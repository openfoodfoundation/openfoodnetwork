require 'spec_helper'

feature "shopping with variant overrides defined", js: true, retry: 3 do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include CheckoutWorkflow
  include UIComponentHelper

  let(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:producer) { create(:supplier_enterprise) }
  let(:oc) { create(:simple_order_cycle, suppliers: [producer], coordinator: hub, distributors: [hub]) }
  let(:outgoing_exchange) { oc.exchanges.outgoing.first }
  let(:sm) { hub.shipping_methods.first }
  let(:pm) { hub.payment_methods.first }
  let(:p1) { create(:simple_product, supplier: producer) }
  let(:p2) { create(:simple_product, supplier: producer) }
  let(:p3) { create(:simple_product, supplier: producer, on_demand: true) }
  let(:v1) { create(:variant, product: p1, price: 11.11, unit_value: 1) }
  let(:v2) { create(:variant, product: p1, price: 22.22, unit_value: 2) }
  let(:v3) { create(:variant, product: p2, price: 33.33, unit_value: 3) }
  let(:v4) { create(:variant, product: p1, price: 44.44, unit_value: 4) }
  let(:v5) { create(:variant, product: p3, price: 55.55, unit_value: 5, on_demand: true) }
  let(:v6) { create(:variant, product: p3, price: 66.66, unit_value: 6, on_demand: true) }
  let!(:vo1) { create(:variant_override, hub: hub, variant: v1, price: 55.55, count_on_hand: nil, default_stock: nil, resettable: false) }
  let!(:vo2) { create(:variant_override, hub: hub, variant: v2, count_on_hand: 0, default_stock: nil, resettable: false) }
  let!(:vo3) { create(:variant_override, hub: hub, variant: v3, count_on_hand: 0, default_stock: nil, resettable: false) }
  let!(:vo4) { create(:variant_override, hub: hub, variant: v4, count_on_hand: 3, default_stock: nil, resettable: false) }
  let!(:vo5) { create(:variant_override, hub: hub, variant: v5, count_on_hand: 0, default_stock: nil, resettable: false) }
  let!(:vo6) { create(:variant_override, hub: hub, variant: v6, count_on_hand: 6, default_stock: nil, resettable: false) }
  let(:ef) { create(:enterprise_fee, enterprise: hub, fee_type: 'packing', calculator: Calculator::FlatPercentPerItem.new(preferred_flat_percent: 10)) }

  before do
    outgoing_exchange.variants = [v1, v2, v3, v4, v5, v6]
    outgoing_exchange.enterprise_fees << ef
    sm.calculator.preferred_amount = 0
    visit shops_path
    click_link hub.name
  end

  describe "viewing products" do
    it "shows the overridden price" do
      page.should_not have_price with_currency(12.22) # $11.11 + 10% fee
      page.should have_price with_currency(61.11)
    end

    it "looks up stock from the override" do
      # Product should appear but one of the variants is out of stock
      page.should_not have_content v2.options_text

      # Entire product should not appear - no stock
      page.should_not have_content p2.name
      page.should_not have_content v3.options_text

      # On-demand product with VO of no stock should NOT appear
      page.should_not have_content v5.options_text
    end

    it "calculates fees correctly" do
      page.find("#variant-#{v1.id} .graph-button").click
      page.find(".price_breakdown a").click
      page.should have_selector 'li.cost div', text: with_currency(55.55)
      page.should have_selector 'li.packing-fee div', text: with_currency(5.56)
      page.should have_selector 'li.total div', text: "= #{with_currency(61.11)}"
    end

    it "shows the correct prices when products are in the cart" do
      fill_in "variants[#{v1.id}]", with: "2"
      show_cart
      wait_until_enabled 'li.cart a.button'
      visit shop_path
      page.should_not have_price with_currency(12.22)
    end

    # The two specs below reveal an unrelated issue with fee calculation. See:
    # https://github.com/openfoodfoundation/openfoodnetwork/issues/312

    it "shows the overridden price with fees in the quick cart" do
      fill_in "variants[#{v1.id}]", with: "2"
      show_cart
      page.should have_selector "#cart-variant-#{v1.id} .quantity", text: '2'
      page.should have_selector "#cart-variant-#{v1.id} .price", text: with_currency(61.11)
      page.should have_selector "#cart-variant-#{v1.id} .total-price", text: with_currency(122.22)
    end

    it "shows the correct prices in the shopping cart" do
      fill_in "variants[#{v1.id}]", with: "2"
      add_to_cart

      page.should have_selector "tr.line-item.variant-#{v1.id} .cart-item-price", text: with_currency(61.11)
      page.should have_field "order[line_items_attributes][0][quantity]", with: '2'
      page.should have_selector "tr.line-item.variant-#{v1.id} .cart-item-total", text: with_currency(122.22)

      page.should have_selector "#edit-cart .item-total", text: with_currency(122.22)
      page.should have_selector "#edit-cart .grand-total", text: with_currency(122.22)
    end

    it "shows the correct prices in the checkout" do
      fill_in "variants[#{v1.id}]", with: "2"
      click_checkout

      page.should have_selector 'form.edit_order .cart-total', text: with_currency(122.22)
      page.should have_selector 'form.edit_order .shipping', text: with_currency(0.00)
      page.should have_selector 'form.edit_order .total', text: with_currency(122.22)
    end
  end


  describe "creating orders" do
    it "creates the order with the correct prices" do
      fill_in "variants[#{v1.id}]", with: "2"
      click_checkout

      complete_checkout

      o = Spree::Order.complete.last
      o.line_items.first.price.should == 55.55
      o.total.should == 122.22
    end

    it "subtracts stock from the override" do
      fill_in "variants[#{v4.id}]", with: "2"
      click_checkout

      expect do
        expect do
          complete_checkout
        end.to change { v4.reload.count_on_hand }.by(0)
      end.to change { vo4.reload.count_on_hand }.by(-2)
    end

    it "subtracts stock from stock-overridden on_demand variants" do
      fill_in "variants[#{v6.id}]", with: "2"
      click_checkout

      expect do
        expect do
          complete_checkout
        end.to change { v6.reload.count_on_hand }.by(0)
      end.to change { vo6.reload.count_on_hand }.by(-2)
    end

    it "does not subtract stock from overrides that do not override count_on_hand" do
      fill_in "variants[#{v1.id}]", with: "2"
      click_checkout
      expect do
        complete_checkout
      end.to change { v1.reload.count_on_hand }.by(-2)
      vo1.reload.count_on_hand.should be_nil
    end

    it "does not show out of stock flags on order confirmation page" do
      v4.update_attribute :count_on_hand, 0
      fill_in "variants[#{v4.id}]", with: "2"
      click_checkout

      complete_checkout

      page.should_not have_content "Out of Stock"
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

    toggle_billing
    within "#billing" do
      fill_in "Address", with: "123 Street"
      select "Australia", from: "Country"
      select "Victoria", from: "State"
      fill_in "City", with: "Melbourne"
      fill_in "Postcode", with: "3066"
    end

    toggle_shipping
    within "#shipping" do
      choose sm.name
    end

    toggle_payment
    within "#payment" do
      choose pm.name
    end

    place_order
    expect(page).to have_content "Your order has been processed successfully"
  end

  def click_checkout
      show_cart
      wait_until_enabled 'li.cart a.button'
      first(:link, 'Checkout now').click
  end

end
