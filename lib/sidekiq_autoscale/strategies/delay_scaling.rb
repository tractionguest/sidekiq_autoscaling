
class SidekiqAutoscale::Strategies::DelayScaling < SidekiqAutoscale::BaseScaling
  SAMPLE_RANGE = 1.minute
  DELAY_LOG_KEY = "sidekiq_autoscaling:delay_log"
  DELAY_AVERAGE_CACHE_KEY = "sidekiq_autoscaling:delay_average"
  LOG_TAG="[SIDEKIQ_SCALE][DELAY_SCALING]"

  def log_job(job)
    timestamp = Time.current.to_f

    # Gotta do it this way so that each entry is guaranteed to be unique
    zset_payload = {delay: (timestamp - job["enqueued_at"]), jid: job["jid"]}.to_json
    
    # Redis zadd runs in O(log(N)) time, so this should be threaded to avoid blocking
    # Also, it should be connection-pooled, but I can't remember if we're using
    # redis connection pooling anywhere 
    Thread.new {
      $redis.zadd(DELAY_LOG_KEY, timestamp, zset_payload)
    }
  end

  def workload_change_needed?(job)
    workload_too_high? || workload_too_low?
  end

  def scaling_direction(job)
    return -1 if workload_too_low?
    return 1 if workload_too_high?
    0
  end

  private

  def delay_average
    # Only calculate this once every minute - this operation isn't very efficient
    # We may want to offload it to another Redis DB number, which will be just delay keys
    Rails.cache.fetch(DELAY_AVERAGE_CACHE_KEY, expires_in: SAMPLE_RANGE) do
      # Delete old scores that won't be included in the metric
      $redis.zremrangebyscore(DELAY_LOG_KEY, 0, SAMPLE_RANGE.ago.to_f)
      vals = $redis.zrange(DELAY_LOG_KEY, 0, -1).map { |i| JSON.parse(i)['delay'].to_f }
      return 0 if vals.empty?

      vals.instance_eval { reduce(:+) / size.to_f }
    rescue JSON::ParserError => e
      Rails.logger.error(e)
      Rails.logger.error(e.backtrace.join("\n"))
      return 0
    end
  end

  def workload_too_high?
    too_high = delay_average > @scale_up_threshold
    Rails.logger.info("#{LOG_TAG} Workload too high") if too_high
    Rails.logger.debug("#{LOG_TAG} Current average delay: #{delay_average}, max allowed: #{@scale_up_threshold}")
    too_high
  end

  def workload_too_low?
    too_low = delay_average < @scale_down_threshold
    Rails.logger.info("#{LOG_TAG} Workload too low") if too_low
    Rails.logger.debug("#{LOG_TAG} Current average delay: #{delay_average}, min allowed: #{@scale_down_threshold}")
    too_low
  end

  def delay_array
    
  end
end
