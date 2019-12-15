# frozen_string_literal: true

class SidekiqAutoscale::HerokuAdapter
  def initialize
    require "platform-api"
    @app_name = SidekiqAutoscale.adapter_config[:app_name]
    @dyno_name = SidekiqAutoscale.adapter_config[:worker_dyno_name]
    @client = PlatformAPI.connect_oauth(SidekiqAutoscale.adapter_config[:api_key])
  end

  def worker_count
    @client.formation.list(@app_name)
           .select {|i| i["type"] == @dyno_name }
           .map {|i| i["quantity"] }
           .reduce(0, &:+)
  rescue Excon::Errors::Error => e
    SidekiqAutoscale.on_scaling_error(e)
    0
  end

  def worker_count=(n)
    SidekiqAutoscale.logger.info("[SIDEKIQ_SCALE][HEROKU_ACTION] Setting new worker count to #{n} (is currenly #{worker_count})")
    return if n == worker_count

    @client.formation.update(@app_name, @dyno_name, quantity: n)
  rescue Excon::Errors::Error, Heroku::API::Errors::Error => e
    SidekiqAutoscale.on_scaling_error(e)
  end
end
