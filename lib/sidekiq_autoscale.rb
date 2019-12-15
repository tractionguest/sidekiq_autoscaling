# frozen_string_literal: true

require "redlock"
require "sidekiq/api"

require "sidekiq_autoscale/railtie"
require "sidekiq_autoscale/exception"
require "sidekiq_autoscale/sidekiq_interface"
require "sidekiq_autoscale/strategies/base_scaling"
require "sidekiq_autoscale/strategies/delay_scaling"
require "sidekiq_autoscale/strategies/linear_scaling"
require "sidekiq_autoscale/strategies/oldest_job_scaling"
require "sidekiq_autoscale/adapters/nil_adapter"
require "sidekiq_autoscale/adapters/heroku_adapter"
require "sidekiq_autoscale/middleware"
require "sidekiq_autoscale/config/shared_configs"

module SidekiqAutoscale
  class << self
    puts "Lefty loader"
    include SidekiqAutoscale::Config::SharedConfigs

    def configure
      yield config
    end
  end
end
