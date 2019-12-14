# frozen_string_literal: true

require "yaml"
require "erb"
require "fileutils"

module SidekiqAutoscale
  module Config
    module FileLoader
      def self.load(cfile, environment="development")
        return false unless should_run?(cfile)

        base_opts = YAML.safe_load(ERB.new(IO.read(cfile)).result) || {}
        env_opts = base_opts[environment] || {}

        SidekiqAutoscale.config.something = env_opts["something"]&.symbolize_keys || {}
        true
      end

      def self.should_run?(cfile)
        File.exist?(cfile)
      end
    end
  end
end
