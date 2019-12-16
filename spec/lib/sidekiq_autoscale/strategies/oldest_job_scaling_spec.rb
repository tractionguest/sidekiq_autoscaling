# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::Strategies::OldestJobScaling, type: :model do
  subject(:strategy) { described_class.new }
  let(:scale_up_at) { 2.0 }
  let(:scale_down_at) { 1.0 }

  let(:sidekiq_interface) { instance_double ::SidekiqAutoscale::SidekiqInterface }

  before do
    allow(sidekiq_interface).to receive(:latency).and_return(current_oldest_job)
    SidekiqAutoscale.instance_variable_set(:@sidekiq_interface, sidekiq_interface)
    SidekiqAutoscale.config.scale_down_threshold = scale_down_at
    SidekiqAutoscale.config.scale_up_threshold = scale_up_at
  end

  after do
    SidekiqAutoscale.instance_variable_set(:@sidekiq_interface, nil)
  end

  context "when no scaling is needed" do
    let(:current_oldest_job) { 1.5 }

    it { expect(strategy.workload_change_needed?(nil)).to eq false }
    it { expect(strategy.scaling_direction(nil)).to eq 0 }
  end

  context "when scaling up is needed" do
    let(:current_oldest_job) { scale_up_at + 1.0 }

    it { expect(strategy.workload_change_needed?(nil)).to eq true }
    it { expect(strategy.scaling_direction(nil)).to eq 1 }
  end

  context "when scaling down is needed" do
    let(:current_oldest_job) { scale_down_at / 2 }

    it { expect(strategy.workload_change_needed?(nil)).to eq true }
    it { expect(strategy.scaling_direction(nil)).to eq -1 }
  end
end
