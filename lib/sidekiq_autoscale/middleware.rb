# frozen_string_literal: true

module SidekiqAutoscale
  class Middleware
    LAST_SCALED_AT_EVENT_KEY = "sidekiq_autoscaling:last_scaled_at"
    SCALING_LOCK_KEY = "sidekiq_autoscaling:scaling_lock"
    LOG_TAG = "[SIDEKIQ_SCALE][SCALING_EVENT]"
    WORKER_COUNT_KEY = "sidekiq_autoscaling/current_worker_count"

    # @param [Object] worker the worker instance
    # @param [Hash] job the full job payload
    #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
    # @param [String] queue the name of the queue the job was pulled from
    # @yield the next middleware in the chain or worker `perform` method
    # @return [Void]
    def call(_worker_class, job, _queue)
      SidekiqAutoscale.strategy_klass.log_job(job) # In case the scaling strategy needs to record job-specific stuff before it runs
      yield # Run the job, THEN scale the cluster
      begin
        return unless SidekiqAutoscale.strategy_klass.workload_change_needed?(job)

        new_worker_count = worker_count + (SidekiqAutoscale.scale_by * SidekiqAutoscale.strategy_klass.scaling_direction(job))
        set_worker_count(new_worker_count, event_id: job["jid"])
      rescue StandardError => e
        SidekiqAutoscale.logger.error(e)
        SidekiqAutoscale.on_scaling_error(e)
      end
    end

    private

    def worker_count
      SidekiqAutoscale.cache.fetch(WORKER_COUNT_KEY, expires_in: 1.minute) do
        SidekiqAutoscale.adapter_klass.worker_count
      end
    end

    def set_worker_count(n, event_id: SecureRandom.hex)
      clamped = n.clamp(SidekiqAutoscale.min_workers, SidekiqAutoscale.max_workers)

      SidekiqAutoscale.lock_manager.lock(SCALING_LOCK_KEY, SidekiqAutoscale.lock_time) do |locked|
        # Not awesome, but gotta handle the initial nil case
        last_scaled_at = SidekiqAutoscale.redis_client.get(LAST_SCALED_AT_EVENT_KEY).to_f
        SidekiqAutoscale.logger.debug <<~LOG
          #{LOG_TAG}[#{event_id}] Concurrency lock obtained: #{locked}"
          Last scaled [#{Time.current.to_i - last_scaled_at.to_i}] seconds ago"
          Scaling every [#{SidekiqAutoscale.min_scaling_interval}] seconds"
        LOG

        if locked && (last_scaled_at < SidekiqAutoscale.min_scaling_interval.seconds.ago.to_f)
          SidekiqAutoscale.adapter_klass.worker_count = clamped
          SidekiqAutoscale.cache.delete(WORKER_COUNT_KEY)
          SidekiqAutoscale.redis_client.set(LAST_SCALED_AT_EVENT_KEY, Time.current.to_f)
          SidekiqAutoscale.on_scaling_event(
            target_workers:       clamped,
            event_id:             event_id,
            current_worker_count: worker_count,
            last_scaled_at:       last_scaled_at
          )
        else
          SidekiqAutoscale.logger.debug("#{LOG_TAG}[#{event_id}] ***NOT SCALING***")
        end

        SidekiqAutoscale.logger.debug("#{LOG_TAG}[#{event_id}] RELEASING LOCK #{locked}") if locked
      end
    end
  end
end
