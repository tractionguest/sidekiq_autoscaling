# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::Config::SharedConfigs, type: :model do
  subject(:config) { SidekiqAutoscale }
  before do
    SidekiqAutoscale.config = ActiveSupport::OrderedOptions.new
    SidekiqAutoscale.instance_variable_set(:@adapter_klass, nil)
    SidekiqAutoscale.instance_variable_set(:@strategy_klass, nil)
  end
  
  it { expect(config.strategy_klass).to be_kind_of(::SidekiqAutoscale::Strategies::BaseScaling) }
  it { expect(config.adapter_klass).to be_kind_of(::SidekiqAutoscale::NilAdapter) }
end
