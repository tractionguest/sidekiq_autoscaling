# frozen_string_literal: true

module SidekiqAutoscale
  class Middleware
    STRATEGIES = SidekiqAutoscale::BaseScaling.subclasses.freeze
    MIN_AUTOSCALING_INTERVAL = 5.minutes
    SCALING_API_CALL_LOCK_TIME = 5_000

    LAST_SCALED_AT_EVENT_KEY = "sidekiq_autoscaling:last_scaled_at"
    SCALING_LOCK_KEY = "sidekiq_autoscaling:scaling_lock"

    LOG_TAG = "[SIDEKIQ_SCALE][SCALING_EVENT]"

    WORKER_COUNT_KEY = "sidekiq_autoscaling/current_worker_count"

    def initialize
      @adapter = adapter
      @sidekiq_interface = sidekiq_interface
      @lock_manager = lock_manager
      @strategy = SidekiqScaling.strategy_picker(strategy).new
      @min_workers = min_workers
      @max_workers = max_workers
      @strategy.sidekiq_interface = @sidekiq_interface
      @scale_by = scale_by
      Rails.logger.info <<~LOG
        [SIDEKIQ_SCALE] Scaling strategy: #{@strategy.class.name}
        [SIDEKIQ_SCALE] Min workers: #{@min_workers}
        [SIDEKIQ_SCALE] Max workers: #{@max_workers}
        [SIDEKIQ_SCALE] Scaling by: #{@scale_by}
        [SIDEKIQ_SCALE] Provider adapter: #{@adapter.class.name}
      LOG
    end

    # @param [Object] worker the worker instance
    # @param [Hash] job the full job payload
    #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
    # @param [String] queue the name of the queue the job was pulled from
    # @yield the next middleware in the chain or worker `perform` method
    # @return [Void]
    def self.call(_worker_class, job, _queue)
      @strategy.log_job(job) # In case the scaling strategy needs to record job-specific stuff before it runs
      delayed_by_seconds = Time.current - Time.at(job["created_at"]) # We can also record this in Librato
      yield # Run the job, THEN scale the cluster
      begin
        return unless @strategy.workload_change_needed?(job)

        new_worker_count = worker_count + (@scale_by * @strategy.scaling_direction(job))
        set_worker_count(new_worker_count, event_id: job["jid"])
      rescue StandardError => e
        Rails.logger.error(e)
        Rails.logger.error(e.backtrace.join("\n"))
        SidekiqAutoscale.on_error&.call(e)
      end
    end

    private

    def self.strategy_picker(strat)
      strat_klass_name = SidekiqAutoscale::STRATEGIES.map(&:to_s).find {|i| i.end_with?("#{strat.to_s.camelize}Scaling") }
      raise StandardError("#{LOG_TAG} Unknown scaling strategy: [#{strat.to_s.camelize}Scaling]") if strat_klass_name.nil?

      strat_klass_name.constantize
    end

    def worker_count
      Rails.cache.fetch(WORKER_COUNT_KEY, expires_in: 1.minute) do
        @adapter.worker_count
      end
    end

    def set_worker_count(n, event_id: SecureRandom.hex)
      clamped = n.clamp(@min_workers, @max_workers)
      Rails.logger.info <<~LOG
        #{LOG_TAG}[#{event_id}] --- START ---
        #{LOG_TAG}[#{event_id}] Current number of workers: #{worker_count}
        #{LOG_TAG}[#{event_id}] New number of workers: #{clamped}
      LOG
      Rails.logger.debug <<~LOG
        #{LOG_TAG}[#{event_id}] Min workers: #{@min_workers}
        #{LOG_TAG}[#{event_id}] Max workers: #{@max_workers}
        #{LOG_TAG}[#{event_id}] Unclamped target workers: #{n}
      LOG

      @lock_manager.lock(SCALING_LOCK_KEY, SCALING_API_CALL_LOCK_TIME) do |locked|
        # Not awesome, but gotta handle the initial nil case
        last_scaled_at = $redis.get(LAST_SCALED_AT_EVENT_KEY).to_f
        Rails.logger.debug("#{LOG_TAG}[#{event_id}] Concurrency lock obtained: #{locked}")
        Rails.logger.debug("#{LOG_TAG}[#{event_id}] Last scaled [#{Time.current.to_i - last_scaled_at.to_i}] seconds ago")
        Rails.logger.debug("#{LOG_TAG}[#{event_id}] Scaling every [#{MIN_AUTOSCALING_INTERVAL}] seconds ago")

        if locked && (last_scaled_at < MIN_AUTOSCALING_INTERVAL.ago.to_f)
          Rails.logger.debug("#{LOG_TAG}[#{event_id}] ***SCALING!!!***")
          @adapter.worker_count = clamped
          Rails.cache.delete(WORKER_COUNT_KEY)
          $redis.set(LAST_SCALED_AT_EVENT_KEY, Time.current.to_f)
        else
          Rails.logger.debug("#{LOG_TAG}[#{event_id}] ***NOT SCALING***")
        end

        Rails.logger.debug("#{LOG_TAG}[#{event_id}] RELEASING LOCK #{locked}") if locked
        Rails.logger.info("#{LOG_TAG}[#{event_id}] --- END ---")
      end
    end
  end
end
