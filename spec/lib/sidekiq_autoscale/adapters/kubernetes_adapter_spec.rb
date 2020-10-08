# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::KubernetesAdapter, type: :model do
  subject(:adapter) { described_class.new }
  let(:deployment_name) { "myapp-sidekiq" }
  let(:on_error_block) { proc {|_| @error_block_fired = true } }

  let(:namespace) { "default" }
  let(:deployments_uri) { "https://192.168.100.100:6443/apis/apps/v1/namespaces/#{namespace}/deployments" }

  let(:client_double) { double("K8sClient") }
  let(:k8s_api_call) { double("K8sApiCall") }
  let(:k8s_resources) { double("get") }
  let(:deployment_object) { OpenStruct.new(spec: OpenStruct.new(replicas: replicas)) }
  let(:file_double) { instance_double(File, read: "stubbed read") }

  before do
    @error_block_fired = false
    WebMock.disable_net_connect!
    SidekiqAutoscale.configure do |c|
      c.on_scaling_error = on_error_block
      c.adapter_config = {
        deployment_name: deployment_name
      }
    end
  end

  before do
    allow(File).to receive(:read).and_call_original { |&block| block.call(file_double) }
    allow(File).to receive(:read).with("/run/secrets/kubernetes.io/serviceaccount/namespace").and_return(namespace)
    allow(K8s::Client).to receive(:autoconfig).and_return(client_double)
    allow(client_double).to receive(:api).with("apps/v1").and_return(k8s_api_call)
    allow(k8s_api_call).to receive(:resource).and_return(k8s_resources)
    allow(k8s_resources).to receive(:get).and_return(deployment_object)
    allow(k8s_resources).to receive(:merge_patch)
  end

  before do
    stub_request(:get, "#{deployments_uri}/#{deployment_name}")
        .to_return(body: deployment_object.to_json,
                   headers: {"Content-Type" => "application/json"})

    stub_request(:post, "#{deployments_uri}/#{deployment_name}")
        .to_return(headers: {"Content-Type" => "application/json"},
                   status: 200)
  end

  after do
    WebMock.reset!
    @error_block_fired = false
  end

  context "update 1" do
    let(:replicas) { 1 }
    it { expect(adapter.worker_count).to eq 1 }
  end

  context "update 100" do
    let(:replicas) { 100 }
    it { expect { adapter.worker_count = 100 }.not_to raise_error }
    it { expect { adapter.worker_count = 100 }.not_to change { @error_block_fired } }
  end

  context "do not raise error if kube unauthorized" do
    let(:replicas) { 1 }
    let(:namespace) { "unauthorized-namespace" }

    before do
      stub_request(:get, "#{deployments_uri}/#{deployment_name}")
          .to_return(headers: {"Content-Type" => "application/json"},
                     status: 403)
    end

    it { expect { adapter.worker_count = 1 }.not_to raise_error }
  end

end
