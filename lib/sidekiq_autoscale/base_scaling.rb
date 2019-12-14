# frozen_string_literal: true

class SidekiqAutoscale::BaseScaling
  SCALE_UP_THRESHOLD = ENV.fetch("SIDEKIQ_SCALE_UP_THRESHOLD", 5.0).to_f # 5 is just a magic number. Should be tweaked
  SCALE_DOWN_THRESHOLD = ENV.fetch("SIDEKIQ_SCALE_DOWN_THRESHOLD", 1.0).to_f # 1 is just a magic number. Should be tweaked
  attr_accessor :sidekiq_interface

  def initialize(scale_up_threshold: SCALE_UP_THRESHOLD,
                 scale_down_threshold: SCALE_DOWN_THRESHOLD)
    @scale_up_threshold = scale_up_threshold
    @scale_down_threshold = scale_down_threshold
  end

  # This strategy doesn't care about individual job metrics
  def log_job(_job); end

  def workload_change_needed?(_job)
    false
  end

  def scaling_direction(_job)
    0
  end
end

# Needs to be at the bottom to avoid a circular dependency error
Dir[Rails.root.join("app", "lib", "sidekiq_scaling", "strategies", "*.rb")].each {|f| require_dependency f }
