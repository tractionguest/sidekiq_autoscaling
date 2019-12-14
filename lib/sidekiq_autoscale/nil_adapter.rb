# frozen_string_literal: true

class SidekiqAutoscaling::NilAdapter
  def initialize
    @sidekiq_adapter = SidekiqAutoscaling::SidekiqInterface
  end

  def worker_count
    @sidekiq_adapter.total_workers
  end

  def worker_count=(n)
    Rails.logger.debug("Attempting to autoscale sidekiq to #{n} workers")
  end
end
