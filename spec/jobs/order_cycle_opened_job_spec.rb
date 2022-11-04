# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleOpenedJob do
  let(:oc_opened_before) {
    create(:order_cycle, orders_open_at: Time.zone.now - 1.hour)
  }
  let(:oc_opened_now) {
    create(:order_cycle, orders_open_at: Time.zone.now)
  }
  let(:oc_opening_soon) {
    create(:order_cycle, orders_open_at: Time.zone.now + 1.minute)
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

  pending "doesn't trigger jobs open more than once"
end
