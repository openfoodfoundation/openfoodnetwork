# frozen_string_literal: true

require "spec_helper"
require Rails.root.join("lib/tasks/test_emails/fake_blob")

RSpec.describe FakeBlob do
  subject(:blob) { described_class.new }

  it "returns a report filename" do
    expect(blob.filename).to eq("test-report.csv")
  end

  it "returns a URL for the report" do
    expect(blob.expiring_service_url).to eq("http://example.com/test-report.csv")
  end
end
