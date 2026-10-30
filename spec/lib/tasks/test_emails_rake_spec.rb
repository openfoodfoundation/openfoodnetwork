# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "test:send_emails" do
  before do
    load Rails.root.join("lib/tasks/test_emails/test_emails.rake")
    Rake::Task["test:send_emails"].reenable
  end

  it "defines the email layout test task" do
    expect(Rake::Task.task_defined?("test:send_emails")).to be(true)
  end

  it "depends on the Rails environment" do
    expect(Rake::Task["test:send_emails"].prerequisites).to include("environment")
  end
end
