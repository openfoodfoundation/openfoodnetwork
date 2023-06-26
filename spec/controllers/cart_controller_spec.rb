# frozen_string_literal: true

require 'spec_helper'

describe CartController, type: :controller do
  let(:order) { create(:order) }

  describe "basic behaviour" do
    let(:cart_service) { double }
    let(:errors) { double }

    before do
      allow(CartService).to receive(:new).and_return(cart_service)
    end

    it "returns HTTP success when successful" do
      allow(cart_service).to receive(:populate) { true }
      allow(cart_service).to receive(:valid?) { true }
      post :populate, xhr: true, params: { use_route: :spree }, as: :json
      expect(response.status).to eq(200)
    end

    it "returns failure when unsuccessful" do
      allow(cart_service).to receive(:populate).and_return false
      allow(cart_service).to receive(:valid?) { false }
      allow(cart_service).to receive(:errors) { errors }
      allow(errors).to receive(:full_messages).and_return(["Error: foo"])
      post :populate, xhr: true, params: { use_route: :spree }, as: :json
      expect(response.status).to eq(412)
    end

    it "returns stock levels as JSON on success" do
      allow(controller).to receive(:variant_ids_in) { [123] }
      allow_any_instance_of(VariantsStockLevels).to receive(:call).and_return("my_stock_levels")
      allow(cart_service).to receive(:populate) { true }
      allow(cart_service).to receive(:valid?) { true }

      post :populate, xhr: true, params: { use_route: :spree }, as: :json

      data = JSON.parse(response.body)
      expect(data['stock_levels']).to eq('my_stock_levels')
    end
  end

  context "handling variant overrides correctly" do
    let(:product) { create(:simple_product, supplier: producer) }
    let(:producer) { create(:supplier_enterprise) }
    let!(:variant_in_the_order) { create(:variant) }
    let!(:variant_not_in_the_order) { create(:variant) }

    let(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let!(:variant_override_in_the_order) {
      create(:variant_override, hub: hub, variant: variant_in_the_order, price: 55.55,
                                count_on_hand: 20, default_stock: nil, resettable: false)
    }
    let!(:variant_override_not_in_the_order) {
      create(:variant_override, hub: hub, variant: variant_not_in_the_order, count_on_hand: 7,
                                default_stock: nil, resettable: false)
    }

    let(:order_cycle) {
      create(:simple_order_cycle, suppliers: [producer], coordinator: hub, distributors: [hub])
    }
    let!(:order) { subject.current_order(true) }
    let!(:line_item) {
      create(:line_item, order: order, variant: variant_in_the_order, quantity: 2, max_quantity: 3)
    }

    before do
      variant_in_the_order.on_hand = 4
      variant_not_in_the_order.on_hand = 2
      order_cycle.exchanges.outgoing.first.variants = [variant_in_the_order,
                                                       variant_not_in_the_order]
      order.order_cycle = order_cycle
      order.distributor = hub
      order.save
    end

    it "returns the variant override stock levels of the variant in the order" do
      spree_post :populate, variants: { variant_in_the_order.id => 1 }

      data = JSON.parse(response.body)
      expect(data['stock_levels'][variant_in_the_order.id.to_s]["on_hand"]).to eq 20
    end

    it "returns the variant override stock levels of the variant requested but not in the order" do
      # This test passes because the variant requested gets added to the order
      # If the variant was not added to the order,
      # VariantsStockLevels alternative calculation would fail
      # See #3222 for more details
      # This indicates that the VariantsStockLevels alternative calculation is never reached
      spree_post :populate, variants: { variant_not_in_the_order.id => 1 }

      data = JSON.parse(response.body)
      expect(data['stock_levels'][variant_not_in_the_order.id.to_s]["on_hand"]).to eq 7
    end
  end

  context "adding a group buy product to the cart" do
    it "sets a variant attribute for the max quantity" do
      distributor = create(:distributor_enterprise)
      product = create(:product, group_buy: true)
      variant = product.variants.first
      order_cycle = create(:simple_order_cycle, distributors: [distributor], variants: [variant])

      order = subject.current_order(true)
      allow(order).to receive(:distributor) { distributor }
      allow(order).to receive(:order_cycle) { order_cycle }
      allow(controller).to receive(:current_order).and_return(order)

      expect do
        spree_post :populate, variants: { variant.id => 1 },
                              variant_attributes: { variant.id => { max_quantity: "3" } }
      end.to change(Spree::LineItem, :count).by(1)
    end
  end
end
