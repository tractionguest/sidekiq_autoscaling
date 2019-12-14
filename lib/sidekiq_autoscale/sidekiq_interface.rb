# frozen_string_literal: true

require "sidekiq/api"

class SidekiqAutoscale::SidekiqInterface
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
    process_set.size
  end

  def total_threads
    process_set.map {|w| w["concurrency"] }.reduce(0, &:+)
  end

  def available_threads
    total_threads - busy_threads
  end

  def youngest_worker
    process_set.map {|w| w["started_at"] }.max
  end

  private

  def process_set
    @process_set ||= ::Sidekiq::ProcessSet.new
  end
end
