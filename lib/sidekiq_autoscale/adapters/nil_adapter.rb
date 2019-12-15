# frozen_string_literal: true

module SidekiqAutoscale
  class NilAdapter
    def initialize
      @sidekiq_adapter = SidekiqAutoscale::SidekiqInterface
    end

    def worker_count
      @sidekiq_adapter.total_workers
    end

    def worker_count=(val)
      SidekiqAutoscale.logger.debug("Attempting to autoscale sidekiq to #{val} workers")
    end
  end
end
