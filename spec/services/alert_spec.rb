# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alert do
  around do |example|
    original_config = nil
    Bugsnag.configure do |config|
      original_config = config.dup
      config.api_key ||= "dummy-key"
      config.notify_release_stages = ["test"]
      config.delivery_method = :synchronous
    end

    example.run

    Bugsnag.configure do |config|
      config.api_key ||= original_config.api_key
      config.notify_release_stages = original_config.notify_release_stages
      config.delivery_method = original_config.delivery_method
    end
  end

  it "notifies Bugsnag" do
    expect(Bugsnag).to receive(:notify).with("hey")

    Alert.raise("hey")
  end

  it "adds context" do
    expect_any_instance_of(Bugsnag::Report).to receive(:add_metadata).with(
      :order, { number: "ABC123" }
    )
    expect_any_instance_of(Bugsnag::Report).to receive(:add_metadata).with(
      :env, { referer: "example.com" }
    )

    Alert.raise(
      "hey",
      { order: { number: "ABC123" }, env: { referer: "example.com" } }
    )
  end

  it "is compatible with Bugsnag API" do
    expect_any_instance_of(Bugsnag::Report).to receive(:add_metadata).with(
      :order, { number: "ABC123" }
    )

    Alert.raise("hey") do |payload|
      payload.add_metadata(:order, { number: "ABC123" })
    end
  end

  it "reaches the Bugsnag service for real", :vcr do
    # You need to have a valid Bugsnag API key to record this test.
    # And after recording, you need to check the Bugsnag account for the right
    # data.
    Alert.raise(
      "Testing Bugsnag from RSpec",
      { RSpec: { file: __FILE__ }, env: { BUGSNAG: ENV.fetch("BUGSNAG", nil) } }
    )
  end
end
