# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::Config::SharedConfigs, type: :model do
  subject(:config) { SidekiqAutoscale }
  before do
    SidekiqAutoscale.config = ActiveSupport::OrderedOptions.new
    SidekiqAutoscale.config.scale_up_threshold = 1.0
    SidekiqAutoscale.config.scale_down_threshold = 1.0
    SidekiqAutoscale.config.max_workers = 1.0
    SidekiqAutoscale.config.min_workers = 1.0
    SidekiqAutoscale.instance_variable_set(:@adapter_klass, nil)
    SidekiqAutoscale.instance_variable_set(:@strategy_klass, nil)

  end

  it { expect(config.strategy_klass).to be_kind_of(::SidekiqAutoscale::Strategies::BaseScaling) }
  it { expect(config.adapter_klass).to be_kind_of(::SidekiqAutoscale::NilAdapter) }
  it { expect(config.scale_up_threshold).to be_kind_of(::Float) }
  it { expect(config.scale_down_threshold).to be_kind_of(::Float) }
  it { expect(config.max_workers).to be_kind_of(::Integer) }
  it { expect(config.min_workers).to be_kind_of(::Integer) }
end
