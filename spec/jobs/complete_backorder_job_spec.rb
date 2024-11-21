# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CompleteBackorderJob do
  let(:user) { create(:testdfc_user) }
  let(:urls) { FdcUrlBuilder.new(product_link) }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
  let(:chia_seed_retail_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519468400947"
  }
  let(:orderer) { FdcBackorderer.new(user, urls) }
  let(:order) {
    backorder = orderer.find_or_build_order(ofn_order)
    broker = FdcOfferBroker.new(user, urls)

    bean_offer = broker.best_offer(product_link).offer
    bean_line = orderer.find_or_build_order_line(backorder, bean_offer)
    bean_line.quantity = 3

    chia = broker.catalog_item(chia_seed_retail_link)
    chia_offer = broker.offer_of(chia)
    chia_line = orderer.find_or_build_order_line(backorder, chia_offer)
    chia_line.quantity = 5

    orderer.send_order(backorder).tap do |o|
      exchange.semantic_links.create!(semantic_id: o.semanticId)
    end
  }
  let(:ofn_order) { create(:completed_order_with_totals) }
  let(:distributor) { ofn_order.distributor }
  let(:order_cycle) { ofn_order.order_cycle }
  let(:exchange) { order_cycle.exchanges.outgoing.first }
  let(:beans) { ofn_order.line_items[0].variant }
  let(:chia) { chia_item.variant }
  let(:chia_item) { ofn_order.line_items[1] }

  describe "#perform" do
    before do
      beans.semantic_links << SemanticLink.new(
        semantic_id: product_link
      )
      chia.semantic_links << SemanticLink.new(
        semantic_id: chia_seed_retail_link
      )
      ofn_order.order_cycle = create(
        :simple_order_cycle,
        distributors: [distributor],
        variants: ofn_order.variants,
      )
      ofn_order.save!
    end

    it "completes an order", vcr: true do
      # We are assuming 12 cans in a slab.
      # We got more stock than we need.
      beans.on_demand = true
      beans.on_hand = 13

      chia.on_demand = false
      chia.on_hand = 17
      chia_item.update!(quantity: 7)

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
          beans.on_hand
        }.from(13).to(1)
        .and change {
          current_order.lines[1].quantity.to_i
        }.from(5).to(7)
        .and change {
          exchange.semantic_links.count
        }.by(-1)
    end

    it "removes line items", vcr: true do
      # We are assuming 12 cans in a slab.
      # We backordered 3 slabs, which is 36 cans.
      # And now we would have more than 4 slabs (4*12 + 1 = 49)
      # We got more stock than we need.
      beans.on_demand = true
      beans.on_hand = 49

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
          beans.on_hand
        }.from(49).to(13) # minus 3 backordered slabs (3 * 12 = 36)
    end

    it "reports errors" do
      expect {
        subject.perform(user, distributor, order_cycle, "https://nil")
      }.to enqueue_mail(BackorderMailer, :backorder_incomplete)
        .and raise_error VCR::Errors::UnhandledHTTPRequestError
    end

    it "skips empty backorders" do
      user = nil
      distributor = nil
      order_cycle = nil
      order_id = nil
      backorder = DataFoodConsortium::Connector::Order.new(
        order_id, orderStatus: "dfc-v:Held"
      )
      expect_any_instance_of(FdcBackorderer)
        .to receive(:find_order).and_return(backorder)

      expect {
        subject.perform(user, distributor, order_cycle, order_id)
      }.not_to raise_error
    end
  end
end
