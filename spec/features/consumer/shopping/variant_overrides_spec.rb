require 'spec_helper'

feature "shopping with variant overrides defined", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include CheckoutWorkflow
  include UIComponentHelper

  use_short_wait

  describe "viewing products" do
    let(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:producer) { create(:supplier_enterprise) }
    let(:oc) { create(:simple_order_cycle, suppliers: [producer], coordinator: hub, distributors: [hub]) }
    let(:outgoing_exchange) { oc.exchanges.outgoing.first }
    let(:sm) { hub.shipping_methods.first }
    let(:pm) { hub.payment_methods.first }
    let(:p1) { create(:simple_product, supplier: producer) }
    let(:p2) { create(:simple_product, supplier: producer) }
    let(:v1) { create(:variant, product: p1, price: 11.11, unit_value: 1) }
    let(:v2) { create(:variant, product: p1, price: 22.22, unit_value: 2) }
    let(:v3) { create(:variant, product: p2, price: 33.33, unit_value: 3) }
    let!(:vo1) { create(:variant_override, hub: hub, variant: v1, price: 55.55) }
    let!(:vo2) { create(:variant_override, hub: hub, variant: v2, count_on_hand: 0) }
    let!(:vo3) { create(:variant_override, hub: hub, variant: v3, count_on_hand: 0) }
    let(:ef) { create(:enterprise_fee, enterprise: hub, fee_type: 'packing', calculator: Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)) }

    before do
      ActionMailer::Base.deliveries.clear
      outgoing_exchange.variants << v1
      outgoing_exchange.variants << v2
      outgoing_exchange.variants << v3
      outgoing_exchange.enterprise_fees << ef
      visit shop_path
      click_link hub.name
    end

    it "shows the overridden price" do
      page.should_not have_price "$11.11"
      page.should have_price "$61.11"
    end

    it "looks up stock from the override" do
      # Product should appear but one of the variants is out of stock
      page.should_not have_content v2.options_text

      # Entire product should not appear - no stock
      page.should_not have_content p2.name
      page.should_not have_content v3.options_text
    end

    it "calculates fees correctly" do
      page.find("#variant-#{v1.id} .graph-button").click
      page.find(".price_breakdown a").click
      page.should have_selector 'li.cost div', text: '$55.55'
      page.should have_selector 'li.packing-fee div', text: '$5.56'
      page.should have_selector 'li.total div', text: '= $61.11'
    end

    # The two specs below reveal an unrelated issue with fee calculation. See:
    # https://github.com/openfoodfoundation/openfoodnetwork/issues/312

    it "shows the overridden price with fees in the quick cart" do
      fill_in "variants[#{v1.id}]", with: "2"
      show_cart
      page.should have_selector "#cart-variant-#{v1.id} .quantity", text: '2'
      page.should have_selector "#cart-variant-#{v1.id} .price", text: '$61.11'
      page.should have_selector "#cart-variant-#{v1.id} .total-price", text: '$122.22'
    end

    it "shows the correct prices in the shopping cart" do
      fill_in "variants[#{v1.id}]", with: "2"
      add_to_cart

      page.should have_selector "tr.line-item.variant-#{v1.id} .cart-item-price", text: '$61.11'
      page.should have_field "order[line_items_attributes][0][quantity]", with: '2'
      page.should have_selector "tr.line-item.variant-#{v1.id} .cart-item-total", text: '$122.22'

      page.should have_selector "#edit-cart .item-total", text: '$122.21'
      page.should have_selector "#edit-cart .grand-total", text: '$122.21'
    end

    it "shows the correct prices in the checkout" do
      fill_in "variants[#{v1.id}]", with: "2"
      show_cart
      wait_until_enabled 'li.cart a.button'
      click_link 'Quick checkout'

      page.should have_selector 'form.edit_order .cart-total', text: '$122.21'
      page.should have_selector 'form.edit_order .shipping', text: '$0.00'
      page.should have_selector 'form.edit_order .total', text: '$122.21'
    end

    it "creates the order with the correct prices" do
      fill_in "variants[#{v1.id}]", with: "2"
      show_cart
      wait_until_enabled 'li.cart a.button'
      click_link 'Quick checkout'

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

      ActionMailer::Base.deliveries.length.should == 0
      place_order
      page.should have_content "Your order has been processed successfully"
      ActionMailer::Base.deliveries.length.should == 2
      email = ActionMailer::Base.deliveries.last

      o = Spree::Order.complete.last

      o.line_items.first.price.should == 55.55
      o.total.should == 122.21

      email.body.should include "$122.21"
    end

    it "subtracts stock from the override"
  end
end
