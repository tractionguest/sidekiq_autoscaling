# frozen_string_literal: true

RSpec.shared_context "test adapter", shared_context: :metadata do
  class TestAdapter
    include Singleton
    attr_writer :set_worker_count_proc, :get_worker_count_proc

    def reset
      @set_worker_count_proc = false
      @get_worker_count_proc = false
    end

    def worker_count
      return 1 unless @get_worker_count_proc.respond_to?(:call)

      @get_worker_count_proc.call
    end

    def worker_count=(val)
      return unless @set_worker_count_proc.respond_to?(:call)

      @set_worker_count_proc.call(val)
    end
  end

  let(:test_adapter) { TestAdapter.instance }

  before do
    SidekiqAutoscale.instance_variable_set(:@adapter_klass, test_adapter)
  end
end
