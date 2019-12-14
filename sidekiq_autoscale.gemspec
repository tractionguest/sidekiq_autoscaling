# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "sidekiq_autoscale/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sidekiq_autoscale"
  s.version     = SidekiqAutoscale::VERSION
  s.authors     = ["Steven Allen"]
  s.email       = ["sallen@tractionguest.com"]
  s.homepage    = "https://github.com/tractionguest/sidekiq_autoscaling"
  s.summary     = "A simple gem to handle Sidekiq autoscaling."
  s.description = "A simple gem to handle Sidekiq autoscaling."
  s.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if s.respond_to?(:metadata)
    s.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "platform-api", "~> 2.2"
  s.add_dependency "railties", ">= 4.2"
  s.add_dependency "redlock", "~> 1"
  s.add_dependency "sidekiq"
  s.add_dependency "thor", ">= 0.19"

  s.add_development_dependency "bundler", "~> 1.8"
  s.add_development_dependency "mock_redis", ">= 0.19"
  s.add_development_dependency "guard", ">= 2"
  s.add_development_dependency "guard-bundler", ">= 2"
  s.add_development_dependency "guard-rspec", "~> 4.7"
  s.add_development_dependency "rspec", ">= 3.2", "< 4"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rubocop", ">= 0.50"
  s.add_development_dependency "rubocop-rspec", "~> 1"
  s.add_development_dependency "simplecov", "~> 0.16"
  s.add_development_dependency "simplecov-console", "~> 0.4"
end
