# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CompleteBackorderJob do
  let(:user) { build(:testdfc_user) }
  let(:catalog) { BackorderJob.load_catalog(user) }
  let(:retail_product) {
    catalog.find { |item| item.semanticType == "dfc-b:SuppliedProduct" }
  }
  let(:wholesale_product) {
    flow = catalog.find { |item| item.semanticType == "dfc-b:AsPlannedProductionFlow" }
    catalog.find { |item| item.semanticId == flow.product }
  }
  let(:orderer) { FdcBackorderer.new(user) }
  let(:order) {
    backorder = orderer.find_or_build_order(ofn_order)
    broker = FdcOfferBroker.new(catalog)
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

      # We are assuming 12 cans in a slab.
      # We got more stock than we need.
      variant.on_hand = 13

      ofn_order.order_cycle = create(
        :simple_order_cycle,
        distributors: [distributor],
        variants: [variant],
      )
    end

    it "completes an order", vcr: true do
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
  end
end
