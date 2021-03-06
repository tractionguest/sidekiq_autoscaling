# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::Middleware, type: :model do
  include_context "test strategy"
  subject { described_class.new }
  let(:job) {
    {
      "created_at": Time.current.to_i,
      "jid":        SecureRandom.hex
    }.with_indifferent_access
  }

  let(:on_error_block) { proc {|_| @error_block_fired = true } }
  let(:on_event_block) { proc {|_| @event_block_fired = true } }

  let(:on_head_bump) { proc {|_| @on_head_bump_fired = true } }
  let(:on_toe_stub) { proc {|_| @on_toe_stub_fired = true } }

  after { TestStrategy.instance.reset }

  before do
    @error_block_fired = false
    @event_block_fired = false
    @head_bump_fired = false
    @toe_stub_fired = false
    SidekiqAutoscale.configure do |c|
      c.on_scaling_error = on_error_block
      c.on_scaling_event = on_event_block
      c.on_head_bump = on_head_bump
      c.on_toe_stub = on_toe_stub
    end
  end

  let(:call_block) do
    subject.call(nil, job, nil) do; end
  end

  it { is_expected.not_to be_nil }
  it { expect { call_block }.not_to raise_error }

  context "when scaling strategy raises an error on logger" do
    before do
      TestStrategy.instance.log_job_proc = proc {|_| raise StandardError.new }
    end

    it { expect { call_block }.to raise_error(StandardError) }
  end

  context "when scaling strategy raises an error on workload change" do
    before do
      TestStrategy.instance.workload_change_proc = proc {|_| raise StandardError.new }
    end

    it { expect { call_block }.not_to raise_error }
    it { expect { call_block }.to change { @error_block_fired } }
  end

  context "when sidekiq job raises an error" do
    let(:call_block) do
      subject.call(nil, job, nil) do
        raise StandardError.new
      end
    end

    it { expect { call_block }.to raise_error(StandardError) }
  end

  context "when scaling strategy requires scaling up" do
    include_context "test adapter"
    before do
      @worker_change = 0
      TestStrategy.instance.workload_change_proc = proc {|_| true }
      TestStrategy.instance.scaling_direction_proc = proc {|_| 1 }
      TestAdapter.instance.set_worker_count_proc = proc {|n| @worker_change = n }
      TestAdapter.instance.get_worker_count_proc = proc { 1 }
    end

    after { @worker_change = nil }

    it { expect { call_block }.to change { @worker_change } }
    it { expect { call_block }.to change { @event_block_fired } }
    it { expect { call_block }.to change { @on_head_bump_fired } }
  end

  context "when scaling strategy requires scaling down" do
    include_context "test adapter"
    before do
      @worker_change = 0
      TestStrategy.instance.workload_change_proc = proc {|_| true }
      TestStrategy.instance.scaling_direction_proc = proc {|_| -1 }
      TestAdapter.instance.set_worker_count_proc = proc {|n| @worker_change = n }
      TestAdapter.instance.get_worker_count_proc = proc { 1 }
    end

    after { @worker_change = nil }

    it { expect { call_block }.to change { @worker_change } }
    it { expect { call_block }.to change { @event_block_fired } }
    it { expect { call_block }.to change { @on_toe_stub_fired } }
  end
end
