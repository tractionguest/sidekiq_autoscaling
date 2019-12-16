# frozen_string_literal: true

require "rails"

module SidekiqAutoscale
  class Railtie < ::Rails::Railtie
    config.sidekiq_autoscale = ActiveSupport::OrderedOptions.new

    config.after_initialize do
      SidekiqAutoscale.logger.info <<~LOG
        [SIDEKIQ_SCALE] Scaling strategy: #{SidekiqAutoscale.strategy}
        [SIDEKIQ_SCALE] Min workers: #{SidekiqAutoscale.min_workers}
        [SIDEKIQ_SCALE] Max workers: #{SidekiqAutoscale.max_workers}
        [SIDEKIQ_SCALE] Scaling by: #{SidekiqAutoscale.scale_by}
        [SIDEKIQ_SCALE] Provider adapter: #{SidekiqAutoscale.adapter}
      LOG
    end
  end
end
