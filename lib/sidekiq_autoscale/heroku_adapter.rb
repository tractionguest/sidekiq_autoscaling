# frozen_string_literal: true

class SidekiqAutoscaling::HerokuAdapter
  # HEROKU_APP_NAME is automatically set with this heroku plugin:
  # heroku labs:enable runtime-dyno-metadata
  def initialize(dyno_name: "worker",
                 auth: ENV.fetch("HEROKU_API_AUTH"),
                 app_name: ENV.fetch("HEROKU_APP_NAME"))
    @app_name = app_name
    @dyno_name = dyno_name
    @client = PlatformAPI.connect_oauth(auth)
  end

  def worker_count
    @client.formation.list(@app_name)
           .select {|i| i["type"] == @dyno_name }
           .map {|i| i["quantity"] }
           .reduce(0, &:+)
  rescue Excon::Errors::Error => e
    Rails.logger.error(e)
    0
  end

  def worker_count=(n)
    Rails.logger.info("[SIDEKIQ_SCALE][HEROKU_ACTION] Setting new worker count to #{n} (is currenly #{worker_count})")
    return if n == worker_count

    @client.formation.update(@app_name, @dyno_name, quantity: n)
  rescue Excon::Errors::Error, Heroku::API::Errors::Error => e
    Rails.logger.error(e)
  end
end
