# frozen_string_literal: true

module SidekiqAutoscale
  module Config
    module SharedConfigs
      LOG_TAG = "[SIDEKIQ_SCALING]"

      attr_writer :config

      def config
        @config ||= ActiveSupport::OrderedOptions.new
      end

      def strategy
        config.strategy || :base
      end

      def strategy_klass
        @strategy_klass ||= begin
          known_strats = [::SidekiqAutoscale::Strategies::BaseScaling.descendants << ::SidekiqAutoscale::Strategies::BaseScaling].flatten.freeze
          strat_klass_name = known_strats.map(&:to_s).find {|i| i.end_with?("#{strategy.to_s.camelize}Scaling") }
          if strat_klass_name.nil?
            raise ::SidekiqAutoscale::Exception.new("#{LOG_TAG} Unknown scaling strategy: [#{strategy.to_s.camelize}Scaling]")
          end

          strat_klass_name.constantize.new
        end
      end

      def adapter
        config.adapter || :nil
      end

      def adapter_klass
        @adapter_klass ||= begin
          known_adapters = [::SidekiqAutoscale::NilAdapter,
                            ::SidekiqAutoscale::HerokuAdapter].freeze
          adapter_klass_name = known_adapters.map(&:to_s).find {|i| i.end_with?("#{adapter.to_s.camelize}Adapter") }
          if adapter_klass_name.nil?
            raise ::SidekiqAutoscale::Exception.new("#{LOG_TAG} Unknown scaling adapter: [#{adapter.to_s.camelize}Adapter]")
          end

          adapter_klass_name.constantize.new
        end
      end

      def adapter_config
        config.adapter_config
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
        (config.scale_by || 1).to_i
      end

      def min_scaling_interval
        (config.min_scaling_interval || 5.minutes).to_i
      end

      def redis_client
        raise ::SidekiqAutoscale::Exception.new("No Redis client defined") unless config.redis_client

        config.redis_client
      end

      def logger
        config.logger ||= Rails.logger
      end

      def cache
        config.cache ||= ActiveSupport::Cache::NullStore.new
      end

      def on_scaling_error(e)
        logger.error(e)
        return unless config.on_scaling_error.respond_to?(:call)

        config.on_scaling_error.call(e)
      end

      def on_scaling_event(event)
        return unless config.on_scaling_event.respond_to?(:call)

        config.on_scaling_event.call(event)
      end

      def sidekiq_interface
        @sidekiq_interface ||= ::SidekiqAutoscale::SidekiqInterface.new
      end

      def lock_manager
        config.lock_manager ||= ::Redlock::Client.new(Array.wrap(redis_client),
                                                      retry_count:   3,
                                                      retry_delay:   200,
                                                      retry_jitter:  50,
                                                      redis_timeout: 0.1)
      end

      def lock_time
        config.lock_time || 5_000
      end

      private

      def validate_worker_set
        ex_klass = ::SidekiqAutoscale::Exception
        raise ex_klass.new("No max workers set") unless config.max_workers.positive?
        raise ex_klass.new("No min workers set") unless config.min_workers.positive?
        if config.max_workers.to_i < config.min_workers.to_i
          raise ex_klass.new("Max workers must be higher than min workers")
        end
      end

      def validate_scaling_thresholds
        ex_klass = ::SidekiqAutoscale::Exception
        raise ex_klass.new("No scale up threshold set") unless config.scale_up_threshold.positive?
        raise ex_klass.new("No scale down threshold set") unless config.scale_down_threshold.positive?
        if config.scale_up_threshold.to_f < config.scale_down_threshold.to_f
          raise ex_klass.new("Scale up threshold must be higher than scale down threshold")
        end
      end
    end
  end
end
