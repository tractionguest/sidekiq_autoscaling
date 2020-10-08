[![Maintainability](https://api.codeclimate.com/v1/badges/505a50e09d651c0423fd/maintainability)](https://codeclimate.com/github/tractionguest/sidekiq_autoscaling/maintainability)

[![Test Coverage](https://api.codeclimate.com/v1/badges/505a50e09d651c0423fd/test_coverage)](https://codeclimate.com/github/tractionguest/sidekiq_autoscaling/test_coverage)

# SidekiqAutoscale

A simple gem to manage autoscaling of Sidekiq worker pools

## Usage



## Installation
Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_autoscale'
```

And then execute:
```bash
$ bundle install
```

Install the initializer:
```bash
$ rails g sidekiq_autoscale:install
```

This will create a `config/initializers/sidekiq_autoscale.rb` file.

### Installing middleware in Sidekiq chain

Add the scaling middleware to your Sidekiq configuration

```ruby
Sidekiq.configure_server do |config|
  .....
  config.server_middleware do |chain|
    chain.add SidekiqScaling::Middleware
  end
end

```


## Configuration

All configuration can be done in a `SidekiqAutoscale.configure` block, either in a standalone initializer or in `<environment>.rb` files.

Standard configuration looks like this:

```ruby
SidekiqAutoscale.configure do |config|
  config.cache = Rails.cache
  config.logger = Rails.logger
  config.redis = # Put a real Redis client instance here

  # Number of workers will never go below this threshold
  config.min_workers = 1

  # Number of workers will never go above this threshold
  config.max_workers = 20

  # The up and down thresholds used by all scaling strategies
  config.scale_down_threshold = 1.0
  config.scale_up_threshold = 5.0

  # Current strategies are:
  #  :oldest_job - scales based on the age (in seconds) of the oldest job in any Sidekiq queue
  #  :delay_based - scales based on the average age (in seconds) all jobs run in the last minute
  #  :linear - scales based the total number of jobs in all queues, divided by the number of workers
  #  :base - do not scale, ever
  config.strategy = :base

  # Current adapters are:
  #  :nil - scaling events do nothing
  #  :heroku - scale a Heroku dyno

  config.adapter = :heroku

  # Any configuration required for the selected adapter
  # Heroku requires the following:
  config.adapter_config = {
                            api_key: "HEROKU_API_KEY", 
                            worker_dyno_name: "DYNO_WORKER_NAME", 
                            app_name: "HEROKU_APP_NAME"
                          }
  # Kubernetes requires the following:
  config.adapter_config = {
                            deployment_name: "myapp-sidekiq", 
                          }

  # The minimum amount of time to wait between scaling events
  # Useful to tweak based on how long it takes for a new worker
  # to spin up and start working on the pool
  # config.min_scaling_interval = 5.minutes.to_i
  
  # The number of workers to change in a scaling event
  # config.scale_by = 1

  # This proc will be called on a scaling event
  # config.on_scaling_event = Proc.new { |event| Rails.logger.info event.to_json }
  
  # This proc will be called when a scaling event errors out
  # By default, nothing happens
  # config.on_scaling_error = Proc.new { |error| Rails.logger.error error.to_json }
end
```

## Kubernetes

This gem can scale a Kubernetes `Deployment` object that Sidekiq is running in.

Doing so requires the following RBAC config:

```

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: myapp-sidekiq
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "patch"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sidekiq
subjects:
  - kind: ServiceAccount
    name: myapp-sidekiq
roleRef:
  kind: Role
  name: myapp-sidekiq
  apiGroup: rbac.authorization.k8s.io

---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: myapp-sidekiq
```

Then assign your sidekiq deployment the `myapp-sidekiq` service account.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
