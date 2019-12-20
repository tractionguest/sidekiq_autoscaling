# frozen_string_literal: true

require "bundler/setup"
Bundler.setup

require "simplecov"
require "simplecov-console"

(SimpleCov.formatter = SimpleCov::Formatter::Console) if ENV["CI"]

SimpleCov.start do
  add_filter "spec/"
  add_filter "lib/sidekiq_autoscale/railtie.rb"
  add_filter "lib/generators/sidekiq_autoscale/install/install_generator.rb"
  add_filter "lib/sidekiq_autoscale/adapters/nil_adapter.rb"
end

# require "redlock/testing"
# require "sidekiq_autoscale/railtie"
require "sidekiq_autoscale"
# require "sidekiq_autoscale/exception"
# require "sidekiq_autoscale/sidekiq_interface"
# require "sidekiq_autoscale/strategies/base_scaling"
# require "sidekiq_autoscale/strategies/delay_scaling"
# require "sidekiq_autoscale/strategies/linear_scaling"
# require "sidekiq_autoscale/strategies/oldest_job_scaling"
# require "sidekiq_autoscale/adapters/nil_adapter"
# require "sidekiq_autoscale/adapters/heroku_adapter"
# require "sidekiq_autoscale/middleware"
require "active_support/core_ext/hash/indifferent_access"

require "awesome_print"
require "rails"
require "byebug"
require "securerandom"
require "mock_redis"
require "redlock/testing"
require "webmock/rspec"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
Dir[File.expand_path("spec/shared_contexts/**/*.rb")].each {|f| require f }
Dir[File.expand_path("spec/shared_examples/**/*.rb")].each {|f| require f }

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true

  # config.disable_monkey_patching!

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 10

  config.order = :random

  config.before do
    SidekiqAutoscale.configure do |c|
      c.scale_up_threshold = 5.0
      c.scale_down_threshold = 1.0
      c.max_workers = 10
      c.min_workers = 1
      c.redis_client = MockRedis.new
      c.logger = ActiveSupport::Logger.new("log/test.log")
      c.logger.level = Logger::DEBUG
    end
    SidekiqAutoscale.lock_manager.testing_mode = :bypass
  end

  config.after do
    # Blank out whatever configs are set in the tests
    SidekiqAutoscale.instance_variables.each do |var|
      SidekiqAutoscale.instance_variable_set(var, nil)
    end
  end

  # Redlock::Client.try_lock_instances_without_testing = true

  Kernel.srand config.seed
end
