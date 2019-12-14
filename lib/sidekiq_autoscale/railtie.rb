# frozen_string_literal: true

require "rails"

module SidekiqAutoscale
  class Railtie < ::Rails::Railtie
    config.sidekiq_autoscale = ActiveSupport::OrderedOptions.new

    initializer "sidekiq_autoscale.configure", after: :load_config_initializers do |_app|
      env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"

    end
  end
end
