# frozen_string_literal: true

require "sidekiq/api"

class SidekiqAutoscaling::SidekiqInterface
  class << self
    def total_queue_size
      queue_names.map {|q| ::Sidekiq::Queue.new(q).size }.reduce(0, &:+)
    end

    def queue_names
      ::Sidekiq::Queue.all.map(&:name)
    end

    def busy_threads
      ::Sidekiq::Workers.new.map {|_, thread, _| thread }.uniq.size
    end

    def latency
      queue_names.map {|q| ::Sidekiq::Queue.new(q).latency }.max
    end

    def total_workers
      ::Sidekiq::ProcessSet.new.size
    end

    def total_threads
      ::Sidekiq::ProcessSet.new.map {|w| w["concurrency"] }.reduce(0, &:+)
    end

    def available_threads
      total_threads - busy_threads
    end

    def youngest_worker
      ::Sidekiq::ProcessSet.new.map {|w| w["started_at"] }.max
    end
  end
end
