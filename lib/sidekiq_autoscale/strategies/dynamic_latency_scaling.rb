# frozen_string_literal: true

module SidekiqAutoscale
  module Strategies
    class DynamicLatencyScaling < BaseScaling
      LOG_TAG = "[SIDEKIQ_SCALE][DYNAMIC_LATENCY_SCALING]"
      def workload_change_needed?(_job)
        workload_too_high? || workload_too_low?
      end

      def scaling_direction(_job)
        return -1 if workload_too_low?
        return [scale_up_factor.to_i, 1].max if workload_too_high?

        0
      end

      private

      def scale_up_factor
        1 + (latency - scale_up_threshold) / dynamic_multiple_base
      end

      def dynamic_multiple_base
        @dynamic_multiple_base ||= scale_up_threshold - scale_down_threshold
      end

      def workload_too_high?
        too_high = latency > scale_up_threshold
        SidekiqAutoscale.logger.debug("#{LOG_TAG} Workload too high") if too_high
        SidekiqAutoscale.logger.debug("#{LOG_TAG} Current average delay: #{latency}, max allowed: #{scale_up_threshold}")
        too_high
      end

      def workload_too_low?
        too_low = latency < scale_down_threshold
        SidekiqAutoscale.logger.debug("#{LOG_TAG} Workload too low") if too_low
        SidekiqAutoscale.logger.debug("#{LOG_TAG} Current average delay: #{latency}, min allowed: #{scale_down_threshold}")
        too_low
      end

      def latency
        SidekiqAutoscale.sidekiq_interface.latency
      end
    end
  end
end
