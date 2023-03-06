# frozen_string_literal: true

require 'system_helper'

describe "shopping with variant overrides defined" do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include CheckoutRequestsHelper
  include UIComponentHelper

  let(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:producer) { create(:supplier_enterprise) }
  let(:oc) {
    create(:simple_order_cycle, suppliers: [producer], coordinator: hub, distributors: [hub])
  }
  let(:outgoing_exchange) { oc.exchanges.outgoing.first }
  let(:sm) { hub.shipping_methods.first }
  let(:pm) { hub.payment_methods.first }
  let(:product1) { create(:simple_product, supplier: producer) }
  let(:product2) { create(:simple_product, supplier: producer) }
  let(:product3) { create(:simple_product, supplier: producer, on_demand: true) }
  let(:product4) { create(:simple_product, supplier: producer) }
  let(:product1_variant1) { create(:variant, product: product1, price: 11.11, unit_value: 1) }
  let(:product1_variant2) { create(:variant, product: product1, price: 22.22, unit_value: 2) }
  let(:product2_variant1) { create(:variant, product: product2, price: 33.33, unit_value: 3) }
  let(:product1_variant3) { create(:variant, product: product1, price: 44.44, unit_value: 4) }
  let(:product3_variant1) {
    create(:variant, product: product3, price: 55.55, unit_value: 5, on_demand: true)
  }
  let(:product3_variant2) {
    create(:variant, product: product3, price: 66.66, unit_value: 6, on_demand: true)
  }
  let(:product4_variant1) { create(:variant, product: product4, price: 77.77, unit_value: 7) }
  let!(:product1_variant1_override) {
    create(:variant_override, :use_producer_stock_settings, hub: hub, variant: product1_variant1,
                                                            price: 55.55, count_on_hand: nil, default_stock: nil, resettable: false)
  }
  let!(:product1_variant2_override) {
    create(:variant_override, hub: hub, variant: product1_variant2, count_on_hand: 0,
                              default_stock: nil, resettable: false)
  }
  let!(:product2_variant1_override) {
    create(:variant_override, hub: hub, variant: product2_variant1, count_on_hand: 0,
                              default_stock: nil, resettable: false)
  }
  let!(:product1_variant3_override) {
    create(:variant_override, hub: hub, variant: product1_variant3, count_on_hand: 3,
                              default_stock: nil, resettable: false)
  }
  let!(:product3_variant1_override) {
    create(:variant_override, hub: hub, variant: product3_variant1, count_on_hand: 0,
                              default_stock: nil, resettable: false)
  }
  let!(:product3_variant2_override) {
    create(:variant_override, hub: hub, variant: product3_variant2, count_on_hand: 6,
                              default_stock: nil, resettable: false)
  }
  let(:enterprise_fee) {
    create(:enterprise_fee, enterprise: hub, fee_type: 'packing', name: "Packing fee",
                            calculator: Calculator::FlatPercentPerItem.new(preferred_flat_percent: 10))
  }
  let!(:product4_variant1_override) {
    create(:variant_override, hub: hub, variant: product4_variant1, count_on_hand: nil,
                              on_demand: true, default_stock: nil, resettable: false)
  }

  before do
    outgoing_exchange.variants = [product1_variant1, product1_variant2, product2_variant1,
                                  product1_variant3, product3_variant1, product3_variant2, product4_variant1]
    outgoing_exchange.enterprise_fees << enterprise_fee
    sm.calculator.preferred_amount = 0
    visit enterprise_shop_path(hub)
  end

  describe "viewing products" do
    it "shows price and stock from the override" do
      expect(page).to have_price with_currency(61.11) # product1_variant1_override.price ($55.55) + 10% fee
      expect(page).not_to have_price with_currency(12.22) # product1_variant1.price ($11.11) + 10% fee

      # Product should appear but one of the variants is out of stock
      expect(page).not_to have_content product1_variant2.options_text

      # Entire product should not appear - no stock
      expect(page).not_to have_content product2.name
      expect(page).not_to have_content product2_variant1.options_text

      # On-demand product with VO of no stock should NOT appear
      expect(page).not_to have_content product3_variant1.options_text
    end

    it "calculates fees correctly" do
      page.find("#variant-#{product1_variant1.id} .graph-button").click
      expect(page).to have_selector 'li', text: "#{with_currency(55.55)} Item cost"
      expect(page).to have_selector 'li', text: "#{with_currency(5.56)} Packing fee"
      expect(page).to have_selector 'li', text: "= #{with_currency(61.11)}"
    end

    it "shows the correct prices when products are in the cart" do
      click_add_to_cart product1_variant1, 2
      visit shop_path
      expect(page).to have_price with_currency(61.11)
    end

    context "clicking the pie-chart icon" do
      before do
        visit shop_path
        within "#variant-#{product1_variant1.id}" do
          page.find(".graph-button").click
        end
      end

      it "shows the price breakdown modal" do
        within(:xpath, '//body') do
          within(".price_breakdown") do
            expect(page).to have_content("Price breakdown")
            expect(page).to have_content(enterprise_fee.name.to_s)
          end
        end
      end
    end

    # The two specs below reveal an unrelated issue with fee calculation. See:
    # https://github.com/openfoodfoundation/openfoodnetwork/issues/312

    it "shows the overridden price with fees in the quick cart" do
      click_add_to_cart product1_variant1, 2
      toggle_cart
      expect(page).to have_selector "#cart-variant-#{product1_variant1.id} .quantity", text: '2'
      expect(page).to have_selector "#cart-variant-#{product1_variant1.id} .total-price",
                                    text: with_currency(122.22)
    end

    it "shows the correct prices in the shopping cart" do
      click_add_to_cart product1_variant1, 2
      edit_cart

      expect(page).to have_selector "tr.line-item.variant-#{product1_variant1.id} .cart-item-price",
                                    text: with_currency(61.11)
      expect(page).to have_field "order[line_items_attributes][0][quantity]", with: '2'
      expect(page).to have_selector "tr.line-item.variant-#{product1_variant1.id} .cart-item-total",
                                    text: with_currency(122.22)

      expect(page).to have_selector "#edit-cart .item-total", text: with_currency(122.22)
      expect(page).to have_selector "#edit-cart .grand-total", text: with_currency(122.22)
    end

    it "shows the correct prices in the checkout" do
      click_add_to_cart product1_variant1, 2
      click_checkout

      expect(page).to have_selector 'form.edit_order .cart-total', text: with_currency(122.22)
      expect(page).to have_selector 'form.edit_order .shipping', text: with_currency(0.00)
      expect(page).to have_selector 'form.edit_order .total', text: with_currency(122.22)
    end
  end

  describe "creating orders" do
    it "creates the order with the correct prices" do
      click_add_to_cart product1_variant1, 2
      click_checkout

      complete_checkout

      o = Spree::Order.complete.last
      expect(o.line_items.first.price).to eq(55.55)
      expect(o.total).to eq(122.22)
    end

    it "subtracts stock from the override" do
      click_add_to_cart product1_variant3, 2
      click_checkout

      expect do
        expect do
          complete_checkout
        end.to change { product1_variant3.reload.on_hand }.by(0)
      end.to change { product1_variant3_override.reload.count_on_hand }.by(-2)
    end

    it "subtracts stock from stock-overridden on_demand variants" do
      click_add_to_cart product3_variant2, 2
      click_checkout

      expect do
        expect do
          complete_checkout
        end.to change { product3_variant2.reload.on_hand }.by(0)
      end.to change { product3_variant2_override.reload.count_on_hand }.by(-2)
    end

    it "does not subtract stock from overrides that do not override count_on_hand" do
      click_add_to_cart product1_variant1, 2
      click_checkout
      expect do
        complete_checkout
      end.to change { product1_variant1.reload.on_hand }.by(-2)
      expect(product1_variant1_override.reload.count_on_hand).to be_nil
    end

    it "does not subtract stock from variants where the override has on_demand: true" do
      click_add_to_cart product4_variant1, 2
      click_checkout
      expect do
        complete_checkout
      end.to change { product4_variant1.reload.on_hand }.by(0)
      expect(product4_variant1_override.reload.count_on_hand).to be_nil
    end

    it "does not show out of stock flags on order confirmation page" do
      product1_variant3.on_hand = 0
      click_add_to_cart product1_variant3, 2
      click_checkout

      complete_checkout

      expect(page).not_to have_content "Out of Stock"
    end
  end

  private

  def complete_checkout
    checkout_as_guest

    within "#details" do
      fill_in "First Name", with: "Some"
      fill_in "Last Name", with: "One"
      fill_in "Email", with: "test@example.com"
      fill_in "Phone", with: "0456789012"
    end

    within "#billing" do
      fill_in "Address", with: "123 Street"
      select "Australia", from: "Country"
      select "Victoria", from: "State"
      fill_in "City", with: "Melbourne"
      fill_in "Postcode", with: "3066"
    end

    within "#shipping" do
      choose sm.name
    end

    within "#payment" do
      choose pm.name
    end

    place_order
    expect(page).to have_content "Your order has been processed successfully"
  end

  def click_checkout
    toggle_cart
    wait_for_cart
    click_link 'Checkout'
  end
end
