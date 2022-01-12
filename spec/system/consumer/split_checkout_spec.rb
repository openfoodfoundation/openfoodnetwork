# frozen_string_literal: true

require "system_helper"

describe "As a consumer, I want to checkout my order", js: true do
  include ShopWorkflow
  include SplitCheckoutHelper

  let!(:zone) { create(:zone_with_member) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true, allow_guest_orders: false) }
  let(:product) {
    create(:taxed_product, supplier: supplier, price: 10, zone: zone, tax_rate_amount: 0.1)
  }
  let(:variant) { product.variants.first }
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: create(:distributor_enterprise), variants: [variant])
  }
  let(:order) {
    create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil,
                   ship_address_id: nil, state: "cart")
  }

  let(:fee_tax_rate) { create(:tax_rate, amount: 0.10, zone: zone, included_in_price: true) }
  let(:fee_tax_category) { create(:tax_category, tax_rates: [fee_tax_rate]) }
  let(:enterprise_fee) { create(:enterprise_fee, amount: 1.23, tax_category: fee_tax_category) }

  let(:free_shipping) {
    create(:shipping_method, require_ship_address: false, name: "Free Shipping", description: "yellow",
                             calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let(:shipping_tax_rate) { create(:tax_rate, amount: 0.25, zone: zone, included_in_price: true) }
  let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
  let(:shipping_with_fee) {
    create(:shipping_method, require_ship_address: true, tax_category: shipping_tax_category,
                             name: "Shipping with Fee", description: "blue",
                             calculator: Calculator::FlatRate.new(preferred_amount: 4.56))
  }
  let!(:payment_method) { create(:payment_method, distributors: [distributor]) }

  before do
    allow(Flipper).to receive(:enabled?).with(:split_checkout).and_return(true)
    allow(Flipper).to receive(:enabled?).with(:split_checkout, anything).and_return(true)

    add_enterprise_fee enterprise_fee
    set_order order
    add_product_to_cart order, product

    distributor.shipping_methods << free_shipping
    distributor.shipping_methods << shipping_with_fee
  end

  context "guest checkout when distributor doesn't allow guest orders" do
    before do
      visit checkout_path
    end

    it "should display the split checkout login page" do
      expect(page).to have_content distributor.name
      expect(page).to have_current_path("/checkout/guest")
      expect(page).to have_content("Ok, ready to checkout?")
      expect(page).to have_content("Login")
      expect(page).to have_no_content("Checkout as guest")
    end

    it "should be redirected if user enter the url" do
      order.update(state: "payment")
      get checkout_step_path(:details)
      expect(response).to have_http_status(:redirect)
      expect(page).to have_current_path("/checkout/guest")
    end

    it "should redirect to the login page when clicking the login button" do
      click_on "Login"
      expect(page).to have_current_path "/"
    end
  end

  context "as a guest user" do
    before do
      distributor.update!(allow_guest_orders: true)
      order.update!(distributor_id: distributor.id)
      visit checkout_path
    end

    it "should display the split checkout login/guest page" do
      expect(page).to have_content distributor.name
      expect(page).to have_current_path("/checkout/guest")
      expect(page).to have_content("Ok, ready to checkout?")
      expect(page).to have_content("Login")
      expect(page).to have_content("Checkout as guest")
    end

    it "should display the split checkout details page" do
      click_on "Checkout as guest"
      expect(page).to have_content distributor.name
      expect(page).to have_current_path("/checkout/details")
      expect(page).to have_content("1 - Your details")
      expect(page).to have_selector("div.checkout-tab.selected", text: "1 - Your details")
      expect(page).to have_content("2 - Payment method")
      expect(page).to have_content("3 - Order summary")
    end

    it "should display error when fields are empty" do
      click_on "Checkout as guest"
      click_button "Next - Payment method"
      expect(page).to have_content("Saving failed, please update the highlighted fields")
      expect(page).to have_css 'span.field_with_errors label', count: 6
      expect(page).to have_css 'span.field_with_errors input', count: 6
      expect(page).to have_css 'span.formError', count: 7
    end

    it "should validate once each needed field is filled" do
      click_on "Checkout as guest"
      fill_in "First Name", with: "Jane"
      fill_in "Last Name", with: "Doe"
      fill_in "Phone number", with: "07987654321"
      fill_in "Address (Street + House Number)", with: "Flat 1 Elm apartments"
      fill_in "City", with: "London"
      fill_in "Postcode", with: "SW1A 1AA"
      choose free_shipping.name

      click_button "Next - Payment method"
      expect(page).to have_current_path("/checkout/payment")
    end

    context "when order is state: 'payment'" do
      it "should allow visit '/checkout/details'" do
        order.update(state: "payment")
        visit checkout_step_path(:details)
        expect(page).to have_current_path("/checkout/details")
      end
    end
  end

  context "as a logged in user" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      visit checkout_path
    end

    describe "filling out delivery details" do
      before do
        fill_out_details
        fill_out_billing_address
      end

      describe "selecting a pick-up shipping method and submiting the form" do
        before do
          choose free_shipping.name
        end

        it "redirects the user to the Payment Method step" do
          fill_in 'Any comments or special instructions?', with: "SpEcIaL NoTeS"
          click_button "Next - Payment method"
          expect(page).to have_current_path("/checkout/payment")
        end
      end

      describe "selecting a delivery shipping method and submiting the form" do
        before do
          choose shipping_with_fee.name
          uncheck "ship_address_same_as_billing"
        end

        it "redirects the user to the Payment Method step" do
          fill_out_shipping_address
          fill_in 'Any comments or special instructions?', with: "SpEcIaL NoTeS"
          click_button "Next - Payment method"
          expect(page).to have_current_path("/checkout/payment")
        end
      end
    end
  end

  context "when I have an out of stock product in my cart" do
    before do
      variant.update!(on_demand: false, on_hand: 0)
    end

    it "returns me to the cart with an error message" do
      visit checkout_path

      expect(page).not_to have_selector 'closing', text: "Checkout now"
      expect(page).to have_selector 'closing', text: "Your shopping cart"
      expect(page).to have_content "An item in your cart has become unavailable"
    end
  end
end
