# frozen_string_literal: true

require "rails"
require "sidekiq_autoscale/config/file_loader"

module SidekiqAutoscale
  class Railtie < ::Rails::Railtie
    config.sidekiq_autoscale = ActiveSupport::OrderedOptions.new

    initializer "sidekiq_autoscale.configure", after: :load_config_initializers do |_app|
      env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"

      %w[config/sidekiq_autoscale.yml.erb config/sidekiq_autoscale.yml].find do |filename|
        SidekiqAutoscale::Config::FileLoader.load(filename, env)
      end
    end
  end
end
