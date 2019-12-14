# frozen_string_literal: true

require "sidekiq_autoscale/railtie"
require "sidekiq_autoscale/config/shared_configs"

module SidekiqAutoscale
  class << self
    include SidekiqAutoscale::Config::SharedConfigs
  end
end
