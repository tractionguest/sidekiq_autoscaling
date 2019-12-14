# frozen_string_literal: true

require "bundler/setup"
Bundler.setup

require "simplecov"
require "simplecov-console"
(SimpleCov.formatter = SimpleCov::Formatter::Console) if ENV["CI"]

SimpleCov.start do
  add_filter "spec/"
  add_filter "lib/sidekiq_autoscale/railtie.rb"
end

require "sidekiq_autoscale/railtie"
require "sidekiq_autoscale/config/shared_configs"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rails"
require "redis"
require "mock_redis"
require "securerandom"

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
Dir[File.expand_path("spec/fixtures/**/*.rb")].each {|f| require f }
Dir[File.expand_path("spec/support/**/*.rb")].each {|f| require f }
Dir[File.expand_path("spec/mocks/**/*.rb")].each {|f| require f }
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

  config.disable_monkey_patching!

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 10

  config.order = :random

  Kernel.srand config.seed

  SidekiqAutoscale.config.cache = ActiveSupport::Cache::NullStore.new
  SidekiqAutoscale.config.logger = Logger.new("log/test.log")
end
