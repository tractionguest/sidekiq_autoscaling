$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "sidekiq_autoscale/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "sidekiq_autoscale"
  spec.version     = SidekiqAutoscale::VERSION
  spec.authors     = ["Steven Allen"]
  spec.email       = ["sallen@tractionguest.com"]
  spec.homepage    = "https://github.com/tractionguest/sidekiq_autoscaling"
  spec.summary     = "A simple gem to handle Sidekiq autoscaling."
  spec.description = "A simple gem to handle Sidekiq autoscaling."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 4"
  spec.add_dependency "platform-api", "~> 2.2"
  spec.add_dependency "redlock", "~> 1"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rubocop"
end
