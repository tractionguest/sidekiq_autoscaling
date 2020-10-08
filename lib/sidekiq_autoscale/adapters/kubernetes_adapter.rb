# frozen_string_literal: true

module SidekiqAutoscale
  # Scale a Kubernetes deployment object.
  class KubernetesAdapter
    def initialize
      require "k8s-ruby"

      namespace = File.read("/run/secrets/kubernetes.io/serviceaccount/namespace")
      deployment_name = SidekiqAutoscale.adapter_config[:deployment_name]

      client = K8s::Client.autoconfig
      @resources = client.api("apps/v1").resource("deployments", namespace: namespace)
      @deployment = @resources.get(deployment_name)
    end

    def worker_count
      @deployment.spec.replicas
    rescue Excon::Errors::Error, K8s::Error, K8s::Error::Forbidden => e
      SidekiqAutoscale.on_scaling_error(e)
      0
    end

    def worker_count=(val)
      return if val == worker_count

      SidekiqAutoscale.logger.info("[SIDEKIQ_SCALE][KUBERNETES_ACTION] Setting new worker count to #{val} (is currenly #{worker_count})")
      @deployment.spec.replicas = val
      @resources.update_resource(@deployment)
    rescue Excon::Errors::Error, K8s::Error, K8s::Error::Forbidden => e
      SidekiqAutoscale.on_scaling_error(e)
    end
  end
end
