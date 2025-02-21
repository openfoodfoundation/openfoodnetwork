# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenOrderCycleJob do
  let(:order_cycle) { create(:simple_order_cycle, orders_open_at: Time.zone.now) }
  subject { OpenOrderCycleJob.perform_now(order_cycle.id) }

  it "marks as open" do
    Timecop.freeze do
      expect {
        subject
        order_cycle.reload
      }
        .to change { order_cycle.opened_at }.to(Time.zone.now)
    end
  end

  it "enqueues webhook job" do
    Timecop.freeze do
      expect(OrderCycles::WebhookService)
        .to receive(:create_webhook_job).with(order_cycle, 'order_cycle.opened', Time.zone.now).once

      subject
    end
  end

  describe "syncing remote products" do
    let!(:user) { create(:testdfc_user, owned_enterprises: [enterprise]) }

    let(:enterprise) { create(:supplier_enterprise) }
    let!(:variant) { create(:variant, name: "Sauce", supplier_id: enterprise.id) }
    let!(:order_cycle) {
      create(:simple_order_cycle, orders_open_at: Time.zone.now,
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
        .and query_database 50
    end
  end
end
