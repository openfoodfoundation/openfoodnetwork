# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleOpenedJob do
  let(:oc_opened_before) {
    create(:order_cycle, orders_open_at: 1.hour.ago)
  }
  let(:oc_opened_now) {
    create(:order_cycle, orders_open_at: Time.zone.now)
  }
  let(:oc_opening_soon) {
    create(:order_cycle, orders_open_at: 1.minute.from_now)
  }

  it "enqueues jobs for recently opened order cycles only" do
    expect(OrderCycleWebhookService)
      .to receive(:create_webhook_job).with(oc_opened_now, 'order_cycle.opened')

    expect(OrderCycleWebhookService)
      .to_not receive(:create_webhook_job).with(oc_opened_before, 'order_cycle.opened')

    expect(OrderCycleWebhookService)
      .to_not receive(:create_webhook_job).with(oc_opening_soon, 'order_cycle.opened')

    OrderCycleOpenedJob.perform_now
  end

  describe "concurrency", concurrency: true do
    let(:breakpoint) { Mutex.new }

    it "doesn't place duplicate job when run concurrently" do
      oc_opened_now

      # Pause jobs when placing new job:
      breakpoint.lock
      allow(OrderCycleOpenedJob).to(
        receive(:new).and_wrap_original do |method, *args|
          breakpoint.synchronize {}
          method.call(*args)
        end
      )

      expect(OrderCycleWebhookService)
        .to receive(:create_webhook_job).with(oc_opened_now, 'order_cycle.opened').once

      # Start two jobs in parallel:
      threads = [
        Thread.new { OrderCycleOpenedJob.perform_now },
        Thread.new { OrderCycleOpenedJob.perform_now },
      ]

      # Wait for both to jobs to pause.
      # This can reveal a race condition.
      sleep 0.1

      # Resume and complete both jobs:
      breakpoint.unlock
      threads.each(&:join)
    end
  end
end
