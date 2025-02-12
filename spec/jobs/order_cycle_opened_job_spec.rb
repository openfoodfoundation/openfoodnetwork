# frozen_string_literal: true

require 'spec_helper'
require_relative '../../engines/dfc_provider/spec/support/authorization_helper'

RSpec.describe OrderCycleOpenedJob do
  include AuthorizationHelper

  #todo: I don't think we need order cycles with exchanges. we don't need the factory at all here.
  # also, maybe rearrange the spec. test selection with opened_at. then webhooks can have it's own define block.
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
    expect(OrderCycles::WebhookService)
      .to receive(:create_webhook_job).with(oc_opened_now, 'order_cycle.opened')

    expect(OrderCycles::WebhookService)
      .not_to receive(:create_webhook_job).with(oc_opened_before, 'order_cycle.opened')

    expect(OrderCycles::WebhookService)
      .not_to receive(:create_webhook_job).with(oc_opening_soon, 'order_cycle.opened')

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
          breakpoint.synchronize { nil }
          method.call(*args)
        end
      )

      expect(OrderCycles::WebhookService)
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

  describe "syncing remote products" do
    let!(:user) { create(:oidc_user, owned_enterprises: [enterprise]) }

    let(:enterprise) { create(:supplier_enterprise) }
    let!(:variant) { create(:variant, name: "Sauce", supplier_id: enterprise.id) }
    let!(:order_cycle) { create(:simple_order_cycle, orders_open_at: Time.zone.now, 
                                suppliers: [enterprise], variants: [variant]) }

    before do
      user.oidc_account.update!(token: allow_token_for(email: user.email))
    end

    # should we move any parts of importing to a separate class, and test it separately? 
    it "synchronises products from a FDC catalog", vcr: true do
      user.update!(oidc_account: build(:testdfc_account))
      # One product is existing in OFN
      product_id =
        "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
      variant.semantic_links << SemanticLink.new(semantic_id: product_id)
        
      expect {
        OrderCycleOpenedJob.perform_now
        variant.reload
        order_cycle.reload
      }.to change { order_cycle.opened_at }
        .and change { enterprise.supplied_products.count }.by(0) # It should not add products, only update existing
        .and change { variant.display_name }
        .and change { variant.unit_value }
        # 18.85 wholesale variant price divided by 12 cans in the slab.
        .and change { variant.price }.to(1.57)
        .and change { variant.on_demand }.to(true)
        .and change { variant.on_hand }.by(0)
        .and query_database 45
    end
  end
end
