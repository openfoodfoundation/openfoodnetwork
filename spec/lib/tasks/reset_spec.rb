# frozen_string_literal: true

RSpec.describe "reset.rake" do
  it "clears job queues" do
    job_class = Class.new do
      include Sidekiq::Job
    end
    job_class.perform_async

    queue = Sidekiq::Queue.all.first # rubocop:disable Rails/RedundantActiveRecordAllMethod

    expect {
      invoke_task "ofn:reset_sidekiq"
    }.to change {
      queue.count
    }.to(0)
  end
end
