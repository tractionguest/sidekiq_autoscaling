# frozen_string_literal: true

class SidekiqAutoscale::NilAdapter
  def initialize
    @sidekiq_adapter = SidekiqAutoscale::SidekiqInterface
  end

  def worker_count
    @sidekiq_adapter.total_workers
  end

  def worker_count=(n)
    SidekiqAutoscale.logger.debug("Attempting to autoscale sidekiq to #{n} workers")
  end
end
