# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::HerokuAdapter, type: :model do
  subject(:adapter) { described_class.new }
  let(:heroku_response) {
    [
      {
        "type":     "worker",
        "quantity": 1
      },
      {
        "type":     "not_worker",
        "quantity": 500
      },
      {
        "type":     "another_not_worker",
        "quantity": 1_000_000
      }
    ]
  }
  let(:app_name) { "not_a_real_app" }
  let(:dyno_name) { "worker" }
  let(:on_error_block) { proc {|_| @error_block_fired = true } }

  before do
    @error_block_fired = false
    WebMock.disable_net_connect!
    SidekiqAutoscale.configure do |c|
      c.on_scaling_error = on_error_block
      c.adapter_config = {
        app_name:         app_name,
        worker_dyno_name: dyno_name,
        api_key:          SecureRandom.hex
      }
    end
  end

  after do
    WebMock.reset!
    @error_block_fired = false
  end

  context "when Heroku API is properly set up" do
    before do
      stub_request(:get, "https://api.heroku.com/apps/#{app_name}/formation")
        .to_return(body:    heroku_response.to_json,
                   headers: {"Content-Type" => "application/json"})

      stub_request(:patch, "https://api.heroku.com/apps/#{app_name}/formation/#{dyno_name}")
        .to_return(body:    heroku_response.to_json,
                   status:  200,
                   headers: {"Content-Type" => "application/json"})
    end

    it { expect(adapter.worker_count).to eq 1 }
    it { expect { adapter.worker_count = 100 }.not_to raise_error }
    it { expect { adapter.worker_count = 100 }.not_to change { @error_block_fired } }
  end

  context "when Heroku API has a bad auth key" do
    include_context "test adapter"

    before do
      stub_request(:get, "https://api.heroku.com/apps/#{app_name}/formation")
        .to_return(body:    heroku_response.to_json,
                   status:  401,
                   headers: {"Content-Type" => "application/json"})

      stub_request(:patch, "https://api.heroku.com/apps/#{app_name}/formation/#{dyno_name}")
        .to_return(body:    heroku_response.to_json,
                   status:  401,
                   headers: {"Content-Type" => "application/json"})
    end

    it { expect(adapter.worker_count).to eq 0 }
    it { expect { adapter.worker_count }.not_to raise_error }
    it { expect { adapter.worker_count }.to change { @error_block_fired } }

    it { expect { adapter.worker_count = 100 }.not_to raise_error }
    it { expect { adapter.worker_count = 100 }.to change { @error_block_fired } }
  end
end
