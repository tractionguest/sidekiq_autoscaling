# frozen_string_literal: true

module SidekiqAutoscale
  module Strategies
    class OldestJobScaling < BaseScaling
      LOG_TAG = "[SIDEKIQ_SCALE][OLDEST_JOB_SCALING]"
      def workload_change_needed?(_job)
        workload_too_high? || workload_too_low?
      end

      def scaling_direction(_job)
        return -1 if workload_too_low?
        return 1 if workload_too_high?

        0
      end

      private

      def workload_too_high?
        too_high = SidekiqAutoscale.sidekiq_interface.latency > SidekiqAutoscale.scale_up_threshold

        SidekiqAutoscale.logger.debug("#{LOG_TAG} Workload too high") if too_high
        SidekiqAutoscale.logger.debug("#{LOG_TAG} Current average delay: #{SidekiqAutoscale.sidekiq_interface.latency}, max allowed: #{SidekiqAutoscale.scale_up_threshold}")
        too_high
      end

      def workload_too_low?
        too_low = SidekiqAutoscale.sidekiq_interface.latency < SidekiqAutoscale.scale_down_threshold
        SidekiqAutoscale.logger.debug("#{LOG_TAG} Workload too low") if too_low
        SidekiqAutoscale.logger.debug("#{LOG_TAG} Current average delay: #{SidekiqAutoscale.sidekiq_interface.latency}, min allowed: #{SidekiqAutoscale.scale_down_threshold}")
        too_low
      end
    end
  end
end
