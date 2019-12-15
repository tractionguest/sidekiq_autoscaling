# frozen_string_literal: true

SidekiqAutoscale.configure do |config|
  config.cache = SidekiqAutoscale.cache
  config.logger = SidekiqAutoscale.logger
  config.redis_client = Redis.new(url: "redis://localhost:6379")
  config.min_workers = 1
  config.max_workers = 20
  config.scale_down_threshold = 1.0
  config.scale_up_threshold = 1.0
  config.strategy = :base

  config.adapter = :heroku
  config.adapter_config = {
    api_key:          "HEROKU_API_KEY",
    worker_dyno_name: "DYNO_WORKER_NAME",
    app_name:         "HEROKU_APP_NAME"
  }

  config.min_scaling_interval = 5.minutes.to_i
  config.scale_by = 2

  config.on_scaling_event = proc {|event| ap event }
  config.on_scaling_error = proc {|error| ap error }
end