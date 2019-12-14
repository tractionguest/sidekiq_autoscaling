# frozen_string_literal: true

require "rails"

module SidekiqAutoscale
  class Railtie < ::Rails::Railtie
    config.sidekiq_autoscale = ActiveSupport::OrderedOptions.new
  end
end
