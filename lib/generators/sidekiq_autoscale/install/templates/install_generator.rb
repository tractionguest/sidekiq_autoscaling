# frozen_string_literal: true

require "rails/generators"

module SidekiqAutoscale
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def generate_install
      template "sidekiq_autoscale_yaml_template.template", "config/sidekiq_autoscale.yml"
      template "sidekiq_autoscale_initializer_template.template", "config/initializers/sidekiq_autoscale.rb"
    end
  end
end
