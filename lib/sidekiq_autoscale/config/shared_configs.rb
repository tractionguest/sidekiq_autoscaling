# frozen_string_literal: true

module SidekiqAutoscale
  module Config
    module SharedConfigs
      attr_writer :config

      puts "Loading ShareConfigs"

      def config
        @config ||= ActiveSupport::OrderedOptions.new
      end

      def strategy; end

      def adapter; end

      def scale_up_threshold; end

      def scale_down_threshold; end

      def scale_by; end

      def min_scaling_interval; end

      def redis_client; end

      def logger; end
    end
  end
end
