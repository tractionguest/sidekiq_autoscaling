# frozen_string_literal: true

module SidekiqAutoscale
  module Strategies
    class LinearScaling < BaseScaling
      LOG_TAG = "[SIDEKIQ_SCALE][LINEAR_SCALING]"

      def workload_change_needed?(_job)
        workload_too_high? || workload_too_low?
      end

      def scaling_direction(_job)
        return 1 if workload_too_high?
        return -1 if workload_too_low?

        0
      end

      private

      # Remove available threads from total queue size in case there's pending
      # tasks that are still spinning up,
      def scheduled_jobs_per_thread
        ((SidekiqAutoscale.sidekiq_interface.total_queue_size - SidekiqAutoscale.sidekiq_interface.available_threads).to_f / SidekiqAutoscale.sidekiq_interface.total_threads.to_f)
      end

      def workload_too_high?
        too_high = scheduled_jobs_per_thread > SidekiqAutoscale.scale_up_threshold
        if too_high
          SidekiqAutoscale.logger.debug("#{LOG_TAG} Workload too low [Scheduled: #{scheduled_jobs_per_thread}, Max: #{SidekiqAutoscale.scale_up_threshold}]")
        end
        too_high
      end

      def workload_too_low?
        too_low = scheduled_jobs_per_thread < SidekiqAutoscale.scale_down_threshold
        if too_low
          SidekiqAutoscale.logger.debug("#{LOG_TAG} Workload too low [Scheduled: #{scheduled_jobs_per_thread}, Min: #{SidekiqAutoscale.scale_down_threshold}]")
        end
        too_low
      end
    end
  end
end
