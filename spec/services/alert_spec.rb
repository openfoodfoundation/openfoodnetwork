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
    pending "Bugsnag calls in CI" if ENV.fetch("CI", false)

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
    pending "Bugsnag calls in CI" if ENV.fetch("CI", false)

    expect_any_instance_of(Bugsnag::Report).to receive(:add_metadata).with(
      :order, { number: "ABC123" }
    )

    Alert.raise("hey") do |payload|
      payload.add_metadata(:order, { number: "ABC123" })
    end
  end

  it "sends ActiveRecord objects" do
    pending "Bugsnag calls in CI" if ENV.fetch("CI", false)

    order = Spree::Order.new(number: "ABC123")

    expect_any_instance_of(Bugsnag::Report).to receive(:add_metadata).with(
      "Spree::Order", hash_including("number" => "ABC123")
    )

    Alert.raise_with_record("Wrong order", order)
  end

  it "notifies Bugsnag when ActiveRecord object is missing" do
    pending "Bugsnag calls in CI" if ENV.fetch("CI", false)

    expect_any_instance_of(Bugsnag::Report).to receive(:add_metadata).with(
      "NilClass", { record_was_nil: true }
    )
    Alert.raise_with_record("Wrong order", nil)
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
