# frozen_string_literal: true

require 'spec_helper'

describe 'checkout endpoints', type: :request do
  include ShopWorkflow

  let!(:shop) { create(:enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:exchange) {
    create(:exchange, order_cycle: order_cycle, sender: order_cycle.coordinator, receiver: shop,
                      incoming: false, pickup_time: "Monday")
  }
  let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }
  let!(:payment_method) {
    create(:bogus_payment_method, distributor_ids: [shop.id], environment: Rails.env)
  }
  let!(:check_payment_method) {
    create(:payment_method, distributor_ids: [shop.id], environment: Rails.env)
  }
  let!(:shipping_method) { create(:shipping_method, distributor_ids: [shop.id]) }
  let!(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method) }
  let!(:order) {
    create(:order, shipments: [shipment], distributor: shop, order_cycle: order_cycle)
  }

  before do
    order_cycle_distributed_variants = double(:order_cycle_distributed_variants)
    allow(OrderCycleDistributedVariants).to receive(:new)
      .and_return(order_cycle_distributed_variants)
    allow(order_cycle_distributed_variants).to receive(:distributes_order_variants?)
      .and_return(true)

    set_order order
  end

  context "when getting the cart `/checkout/cart`" do
    let(:path) { "/checkout/cart" }

    it "redirect to the split checkout" do
      get path
      expect(response.status).to redirect_to("/checkout")

      # follow the redirect
      get response.redirect_url
      expect(response.status).to redirect_to("/checkout/details")
    end
  end
end
