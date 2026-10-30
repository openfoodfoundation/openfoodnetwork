# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EmailTestData" do
  before(:all) do
    rake_file = Rails.root.join("lib/tasks/test_emails2.rake")

    unless Rake::Task.task_defined?("ofn:test_emails")
      load rake_file
    end
  end

  describe "ofn:test_emails task" do
    let(:email_test_data_class) { Object.const_get(:EmailTestData) }
    let(:email_test_data) { instance_double(email_test_data_class, run: nil) }

    before do
      allow(email_test_data_class).to receive(:new).and_return(email_test_data)
    end

    it "ensures sample data exists before sending emails" do
      task = Rake::Task["ofn:test_emails"]
      task.reenable

      allow(Spree::Order).to receive(:any?).and_return(false)
      allow(Enterprise).to receive(:any?).and_return(false)

      sample_task = instance_double(Rake::Task)
      allow(sample_task).to receive(:invoke)

      allow(Rake::Task).to receive(:[]).and_call_original
      allow(Rake::Task).to receive(:[])
        .with("ofn:sample_data")
        .and_return(sample_task)

      task.invoke

      expect(sample_task).to have_received(:invoke).once
      expect(email_test_data).to have_received(:run).once
    end

    it "skips sample_data generation when it already exists" do
      task = Rake::Task["ofn:test_emails"]
      task.reenable

      allow(Spree::Order).to receive(:any?).and_return(true)
      allow(Enterprise).to receive(:any?).and_return(true)

      expect(Rake::Task).not_to receive(:[])
        .with("ofn:sample_data")

      task.invoke

      expect(email_test_data).to have_received(:run).once
    end
  end

  describe "Configuration" do
    let(:configuration_class) do
      Object.const_get(:EmailTestData)::Configuration
    end

    subject(:config) { configuration_class.new }

    describe "#load_email_config" do
      before do
        allow(File).to receive(:exist?).and_call_original
      end

      it "returns the default config when the file is missing" do
        allow(File).to receive(:exist?)
          .with(configuration_class::CONFIG_PATH)
          .and_return(false)

        expect(config.load_email_config).to eq(
          configuration_class::DEFAULT_CONFIG.deep_dup
        )
      end

      it "merges YAML config when the file exists" do
        allow(File).to receive(:exist?)
          .with(configuration_class::CONFIG_PATH)
          .and_return(true)

        allow(YAML).to receive(:load_file)
          .with(configuration_class::CONFIG_PATH)
          .and_return({ "recipient" => "x@example.com" })

        expected_config = configuration_class::DEFAULT_CONFIG.deep_dup
          .deep_merge({ "recipient" => "x@example.com" })

        expect(config.load_email_config).to eq(expected_config)
      end
    end

    describe "#save_email_config" do
      it "writes the YAML file" do
        config_hash = { "recipient" => "a" }

        expect(File).to receive(:write).with(
          configuration_class::CONFIG_PATH,
          config_hash.to_yaml
        )

        config.save_email_config(config_hash)
      end
    end

    describe "#configure_recipient" do
      before do
        allow($stdout).to receive(:puts)
        allow($stdout).to receive(:print)
      end

      it "keeps the current config when input is blank" do
        allow($stdin).to receive(:gets).and_return("\n")

        current = { "recipient" => "old@example.com" }

        expect(config.configure_recipient(current)).to eq(current)
      end

      it "updates the recipient when input is provided" do
        allow($stdin).to receive(:gets)
          .and_return("new@example.com\n")

        current = { "recipient" => "old@example.com" }

        expect(config.configure_recipient(current)).to eq(
          "recipient" => "new@example.com"
        )
      end
    end
  end
end
