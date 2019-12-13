
class SidekiqScaling::Strategies::OldestJobScaling < SidekiqScaling::BaseScaling
  LOG_TAG = "[SIDEKIQ_SCALE][OLDEST_JOB_SCALING]"
  def workload_change_needed?(_job)
    workload_too_high? || workload_too_low?
  end

  def scaling_direction(job)
    return -1 if workload_too_low?
    return 1 if workload_too_high?
    0
  end

  private

  def workload_too_high?
    too_high = sidekiq_interface.latency > @scale_up_threshold
    Rails.logger.info("#{LOG_TAG} Workload too high") if too_high
    Rails.logger.debug("#{LOG_TAG} Current average delay: #{sidekiq_interface.latency}, max allowed: #{@scale_up_threshold}")
    too_high
  end

  def workload_too_low?
    too_low = sidekiq_interface.latency < @scale_down_threshold
    Rails.logger.info("#{LOG_TAG} Workload too low") if too_low
    Rails.logger.debug("#{LOG_TAG} Current average delay: #{sidekiq_interface.latency}, min allowed: #{@scale_down_threshold}")
    too_low
  end
end
