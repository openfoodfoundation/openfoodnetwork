# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CompleteBackorderJob do
  let(:user) { build(:testdfc_user) }
  let(:catalog) {
    VCR.use_cassette(:fdc_catalog) { FdcOfferBroker.load_catalog(user, urls) }
  }
  let(:urls) { FdcUrlBuilder.new(product_link) }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
  let(:retail_product) {
    catalog.find { |item| item.semanticType == "dfc-b:SuppliedProduct" }
  }
  let(:wholesale_product) {
    flow = catalog.find { |item| item.semanticType == "dfc-b:AsPlannedProductionFlow" }
    catalog.find { |item| item.semanticId == flow.product }
  }
  let(:orderer) { FdcBackorderer.new(user, urls) }
  let(:order) {
    backorder = orderer.find_or_build_order(ofn_order)
    broker = FdcOfferBroker.new(user, urls)
    offer = broker.best_offer(retail_product.semanticId).offer
    line = orderer.find_or_build_order_line(backorder, offer)
    line.quantity = 3

    orderer.send_order(backorder)
  }
  let(:ofn_order) { create(:completed_order_with_totals) }
  let(:distributor) { ofn_order.distributor }
  let(:order_cycle) { ofn_order.order_cycle }
  let(:variant) { ofn_order.variants[0] }

  describe "#perform" do
    before do
      variant.semantic_links << SemanticLink.new(
        semantic_id: retail_product.semanticId
      )
      ofn_order.order_cycle = create(
        :simple_order_cycle,
        distributors: [distributor],
        variants: [variant],
      )
    end

    it "completes an order", vcr: true do
      # We are assuming 12 cans in a slab.
      # We got more stock than we need.
      variant.on_hand = 13

      current_order = order

      expect {
        subject.perform(user, distributor, order_cycle, order.semanticId)
        current_order = orderer.find_order(order.semanticId)
      }.to change {
        current_order.orderStatus[:path]
      }.from("Held").to("Complete")
        .and change {
          current_order.lines[0].quantity.to_i
        }.from(3).to(2)
        .and change {
          variant.on_hand
        }.from(13).to(1)
    end

    it "removes line items", vcr: true do
      # We are assuming 12 cans in a slab.
      # We backordered 3 slabs, which is 36 cans.
      # And now we would have more than 4 slabs (4*12 + 1 = 49)
      # We got more stock than we need.
      variant.on_hand = 49

      current_order = order

      expect {
        subject.perform(user, distributor, order_cycle, order.semanticId)
        current_order = orderer.find_order(order.semanticId)
      }.to change {
        current_order.orderStatus[:path]
      }.from("Held").to("Complete")
        .and change {
          current_order.lines.count
        }.from(1).to(0)
        .and change {
          variant.on_hand
        }.from(49).to(13) # minus 3 backordered slabs (3 * 12 = 36)
    end

    it "reports errors" do
      expect(Bugsnag).to receive(:notify).and_call_original

      expect {
        subject.perform(user, distributor, order_cycle, "https://nil")
      }.not_to raise_error

      # Combined example for performance
      expect(Bugsnag).to receive(:notify).and_call_original

      expect {
        subject.perform(user, distributor, order_cycle, "https://nil")
      }.to enqueue_mail(BackorderMailer, :backorder_incomplete)
    end
  end
end
