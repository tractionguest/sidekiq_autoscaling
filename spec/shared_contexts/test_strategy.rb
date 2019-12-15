# frozen_string_literal: true

RSpec.shared_context "test strategy", shared_context: :metadata do
  class TestStrategy
    include Singleton
    attr_writer :workload_change_proc, :log_job_proc, :scaling_direction_proc

    def reset
      @workload_change_proc = false
      @log_job_proc = false
      @scaling_direction_proc = false
    end

    def log_job(job)
      return unless @log_job_proc.respond_to?(:call)

      @log_job_proc.call(job)
    end

    def workload_change_needed?(job)
      return false unless @workload_change_proc.respond_to?(:call)

      @workload_change_proc.call(job)
    end

    def scaling_direction(job)
      return 0 unless @scaling_direction_proc.respond_to?(:call)

      @scaling_direction_proc.call(job)
    end
  end

  let(:test_strat) { TestStrategy.instance }

  before do
    SidekiqAutoscale.instance_variable_set(:@strategy_klass, test_strat)
  end
end
