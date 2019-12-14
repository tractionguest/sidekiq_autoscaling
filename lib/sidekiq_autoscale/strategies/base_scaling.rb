# frozen_string_literal: true

module SidekiqAutoscale
  module Strategies
    class BaseScaling
      # This strategy doesn't care about individual job metrics
      def log_job(_job); end

      def workload_change_needed?(_job)
        false
      end

      def scaling_direction(_job)
        0
      end
    end
  end
end
