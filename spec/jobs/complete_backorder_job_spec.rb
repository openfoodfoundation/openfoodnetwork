# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CompleteBackorderJob do
  let(:user) { build(:testdfc_user) }
  let(:catalog) { BackorderJob.load_catalog(user) }
  let(:product) {
    catalog.find { |item| item.semanticType == "dfc-b:SuppliedProduct" }
  }
  let(:orderer) { FdcBackorderer.new(user) }
  let(:order) {
    ofn_order = build(:order, distributor_id: 1)
    ofn_order.order_cycle = build(:order_cycle)
    backorder = orderer.find_or_build_order(ofn_order)
    offer = FdcOfferBroker.new(nil).offer_of(product)
    line = orderer.find_or_build_order_line(backorder, offer)
    line.quantity = 3

    orderer.send_order(backorder)
  }

  describe "#perform" do
    it "completes an order", vcr: true do
      subject.perform(user, order.semanticId)
      updated_order = orderer.find_order(order.semanticId)
      expect(updated_order.orderStatus[:path]).to eq "Complete"
    end
  end
end
