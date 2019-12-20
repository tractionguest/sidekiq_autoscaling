# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::Strategies::LinearScaling, type: :model do
  subject(:strategy) { described_class.new }
  let(:scale_up_at) { 2.0 }
  let(:scale_down_at) { 1.0 }
  let(:sidekiq_interface) { instance_double ::SidekiqAutoscale::SidekiqInterface }

  before do
    allow(sidekiq_interface).to receive(:total_queue_size).and_return(total_queue_size)
    allow(sidekiq_interface).to receive(:available_threads).and_return(available_threads)
    allow(sidekiq_interface).to receive(:total_threads).and_return(total_threads)

    SidekiqAutoscale.instance_variable_set(:@sidekiq_interface, sidekiq_interface)
    SidekiqAutoscale.config.scale_down_threshold = scale_down_at
    SidekiqAutoscale.config.scale_up_threshold = scale_up_at
  end

  after do
    SidekiqAutoscale.instance_variable_set(:@sidekiq_interface, nil)
  end

  context "when no scaling is needed" do
    let(:total_queue_size) { 2 }
    let(:available_threads) { 0 }
    let(:total_threads) { 2 }

    it { expect(strategy.workload_change_needed?(nil)).to eq false }
    it { expect(strategy.scaling_direction(nil)).to eq 0 }
  end

  context "when there are no running workers" do
    let(:total_queue_size) { 10 }
    let(:available_threads) { 0 }
    let(:total_threads) { 0 }

    it { expect(strategy.workload_change_needed?(nil)).to eq true }
    it { expect(strategy.scaling_direction(nil)).to eq 1 }
  end

  context "when scaling up is needed" do
    let(:total_queue_size) { 3 }
    let(:available_threads) { 0 }
    let(:total_threads) { 1 }

    it { expect(strategy.workload_change_needed?(nil)).to eq true }
    it { expect(strategy.scaling_direction(nil)).to eq 1 }
  end

  context "when scaling down is needed" do
    let(:total_queue_size) { 1 }
    let(:available_threads) { 2 }
    let(:total_threads) { 2 }

    it { expect(strategy.workload_change_needed?(nil)).to eq true }
    it { expect(strategy.scaling_direction(nil)).to eq(-1) }
  end
end
