# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenOrderCycleJob do
  let(:now){ Time.zone.now }
  let(:order_cycle) { create(:simple_order_cycle, orders_open_at: now) }
  subject { OpenOrderCycleJob.perform_now(order_cycle.id) }

  around do |example|
    Timecop.freeze(now) { example.run }
  end

  it "marks as open" do
    expect {
      subject
      order_cycle.reload
    }
      .to change { order_cycle.opened_at }.to(now)
  end

  it "enqueues webhook job" do
    expect(OrderCycles::WebhookService)
      .to receive(:create_webhook_job).with(order_cycle, 'order_cycle.opened', now).once

    subject
  end

  describe "syncing remote products" do
    let!(:user) { create(:testdfc_user, owned_enterprises: [enterprise]) }

    let(:enterprise) { create(:supplier_enterprise) }
    let!(:variant) { create(:variant, name: "Sauce", supplier_id: enterprise.id) }
    let!(:order_cycle) {
      create(:simple_order_cycle, orders_open_at: now,
                                  suppliers: [enterprise], variants: [variant])
    }

    it "synchronises products from a FDC catalog", vcr: true do
      user.update!(oidc_account: build(:testdfc_account))
      # One product is existing in OFN
      product_id =
        "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
      variant.semantic_links << SemanticLink.new(semantic_id: product_id)

      expect {
        subject
        variant.reload
        order_cycle.reload
      }.to change { order_cycle.opened_at }
        .and change { enterprise.supplied_products.count }.by(0) # It shouldn't add, only update
        .and change { variant.display_name }
        .and change { variant.unit_value }
        # 18.85 wholesale variant price divided by 12 cans in the slab.
        .and change { variant.price }.to(1.57)
        .and change { variant.on_demand }.to(true)
        .and change { variant.on_hand }.by(0)
        .and query_database 46
    end
  end

  describe "concurrency", concurrency: true do
    let(:breakpoint) { Mutex.new }

    it "doesn't open order cycle twice" do
      # Pause jobs when placing new job:
      breakpoint.lock
      allow(OpenOrderCycleJob).to(
        receive(:new).and_wrap_original do |method, *args|
          breakpoint.synchronize {} # rubocop:disable Lint/EmptyBlock
          method.call(*args)
        end
      )

      expect(OrderCycles::WebhookService)
        .to receive(:create_webhook_job).with(order_cycle, 'order_cycle.opened', now).once

      # Start two jobs in parallel:
      threads = [
        Thread.new { OpenOrderCycleJob.perform_now(order_cycle.id) },
        Thread.new { OpenOrderCycleJob.perform_now(order_cycle.id) },
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
