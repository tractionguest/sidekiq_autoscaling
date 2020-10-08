# frozen_string_literal: true

module SidekiqAutoscale
  # Scale a Kubernetes deployment object.
  class KubernetesAdapter
    def initialize
      require "k8s-ruby"

      namespace = File.read("/run/secrets/kubernetes.io/serviceaccount/namespace")
      client = K8s::Client.autoconfig

      @deployment_name = SidekiqAutoscale.adapter_config[:deployment_name]
      @resources = client.api("apps/v1").resource("deployments", namespace: namespace)
    end

    def worker_count
      @resources.get(@deployment_name).spec.replicas
    rescue Excon::Errors::Error, K8s::Error, K8s::Error::Forbidden => e
      SidekiqAutoscale.on_scaling_error(e)
      0
    end

    def worker_count=(val)
      return if val == worker_count

      SidekiqAutoscale.logger.info("[SIDEKIQ_SCALE][KUBERNETES_ACTION] Setting new worker count to #{val} (is currenly #{worker_count})")
      @resources.merge_patch(@deployment_name, spec: {replicas: val})
    rescue Excon::Errors::Error, K8s::Error, K8s::Error::Forbidden => e
      SidekiqAutoscale.on_scaling_error(e)
    end
  end
end
