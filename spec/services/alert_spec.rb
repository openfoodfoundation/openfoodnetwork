# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alert do
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
end
