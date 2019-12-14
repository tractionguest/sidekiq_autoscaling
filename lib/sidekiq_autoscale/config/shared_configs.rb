# frozen_string_literal: true

require 'redlock'

module SidekiqAutoscale
  module Config
    module SharedConfigs
      attr_writer :config

      def config
        @config ||= ActiveSupport::OrderedOptions.new
      end

      def strategy
        config.strategy || :base
      end

      def adapter
        config.strategy || :nil
      end

      def scale_up_threshold
        validate_scaling_thresholds
        config.scale_up_threshold.to_f
      end

      def scale_down_threshold
        validate_scaling_thresholds
        config.scale_up_threshold.to_f
      end

      def max_workers
        validate_worker_set
        config.max_workers.to_i
      end

      def min_workers
        validate_worker_set
        config.min_workers.to_i
      end

      def scale_by
        config.scale_by.to_i || 1
      end

      def min_scaling_interval
        (config.min_scaling_interval || 5.minutes).to_i
      end

      def redis_client
        raise SidekiqAutoscale::Exception.new("No Redis client defined") unless config.redis_client
        config.redis_client
      end

      def logger
        config.logger ||= Rails.logger
      end

      def cache
        config.cache ||= Rails.cache
      end

      def on_scaling_error(e)
        return unless config.on_scaling_error.respond_to?(:call)

        config.on_scaling_error.call(e)
      end
  
      def on_scaling_event(event)
        return unless config.on_scaling_event.respond_to?(:call)

        config.on_scaling_event.call(event)
      end
  
      def sidekiq_interface
        @sidekiq_interface ||= SidekiqAutoscale::SidekiqInterface.new
      end

      def redis
        @redis ||= ::Redis.new(url: "redis://localhost:6379")
      end

      def lock_manager
        @lock_manager ||= ::Redlock::Client.new(redis,
                                                retry_count:   3,
                                                retry_delay:   200, # milliseconds
                                                retry_jitter:  50,  # milliseconds
                                                redis_timeout: 0.1)  # seconds)
      end

      private

      def validate_worker_set
        ex_klass = SidekiqAutoscale::Exception
        raise ex_klass.new("No max workers set") unless config.max_workers.positive?
        raise ex_klass.new("No min workers set") unless config.min_workers.positive?
        raise ex_klass.new("Max workers must be higher than min workers") if config.max_workers.to_i < config.min_workers.to_i
      end

      def validate_scaling_thresholds
        ex_klass = SidekiqAutoscale::Exception
        raise ex_klass.new("No scale up threshold set") unless config.scale_up_threshold.positive?
        raise ex_klass.new("No scale down threshold set") unless config.scale_down_threshold.positive?
        raise ex_klass.new("Scale up threshold must be higher than scale down threshold") if config.scale_up_threshold.to_f < config.scale_down_threshold.to_f
      end
    end
  end
end
