# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe "reset.rake" do
  before(:all) do
    Rake.application.rake_require("tasks/reset")
    Rake::Task.define_task(:environment)
  end

  it "clears job queues" do
    job_class = Class.new do
      include Sidekiq::Job
    end
    job_class.perform_async

    queue = Sidekiq::Queue.all.first # rubocop:disable Rails/RedundantActiveRecordAllMethod

    expect {
      Rake.application.invoke_task "ofn:reset_sidekiq"
    }.to change {
      queue.count
    }.to(0)
  end
end
