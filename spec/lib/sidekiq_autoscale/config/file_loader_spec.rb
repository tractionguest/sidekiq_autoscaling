# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqAutoscale::Config::FileLoader do
  subject(:file_loader) { described_class.load(subject_file) }

  context "when file does not exist" do
    let(:subject_file) { "spec/fixtures/this_file_does_not_exist.yml" }

    it { expect { file_loader }.not_to raise_error }
    it { expect(file_loader).to be false }
  end

  context "when file does exist" do
    let(:subject_file) { "spec/fixtures/valid_config.yml" }

    it { expect(file_loader).to be true }

    context "with a valid config file" do
      before { file_loader }

      it { byebug }

      it { expect(SidekiqAutoscale.config.sns_config[:endpoint]).to eq "http://localhost:4575" }
    end
  end
end
