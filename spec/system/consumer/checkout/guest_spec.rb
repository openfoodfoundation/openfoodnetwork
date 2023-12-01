# frozen_string_literal: true

require "system_helper"

describe "As a consumer, I want to checkout my order" do
  include ShopWorkflow
  include CheckoutHelper
  include FileHelper
  include AuthenticationHelper

  let!(:zone) { create(:zone_with_member) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:product) {
    create(:taxed_product, supplier:, price: 10, zone:, tax_rate_amount: 0.1)
  }
  let(:variant) { product.variants.first }
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: create(:distributor_enterprise), variants: [variant])
  }
  let(:order) {
    create(:order, order_cycle:, distributor:, bill_address_id: nil,
                   ship_address_id: nil, state: "cart",
                   line_items: [create(:line_item, variant:)])
  }

  let(:fee_tax_rate) { create(:tax_rate, amount: 0.10, zone:, included_in_price: true) }
  let(:fee_tax_category) { create(:tax_category, tax_rates: [fee_tax_rate]) }
  let(:enterprise_fee) { create(:enterprise_fee, amount: 1.23, tax_category: fee_tax_category) }

  let(:free_shipping_with_required_address) {
    create(:shipping_method, require_ship_address: true,
                             name: "A Free Shipping with required address")
  }
  let(:free_shipping) {
    create(:shipping_method, require_ship_address: false, name: "free Shipping",
                             description: "yellow",
                             calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let(:shipping_tax_rate) { create(:tax_rate, amount: 0.25, zone:, included_in_price: true) }
  let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
  let(:shipping_with_fee) {
    create(:shipping_method, require_ship_address: true, tax_category: shipping_tax_category,
                             name: "Shipping with Fee", description: "blue",
                             calculator: Calculator::FlatRate.new(preferred_amount: 4.56))
  }
  let(:free_shipping_without_required_address) {
    create(:shipping_method, require_ship_address: false,
                             name: "Z Free Shipping without required address")
  }
  let(:tagged_shipping) {
    create(:shipping_method, require_ship_address: false, name: "Local", tag_list: "local")
  }
  let!(:payment_with_fee) {
    create(:payment_method, distributors: [distributor],
                            name: "Payment with Fee", description: "Payment with fee",
                            calculator: Calculator::FlatRate.new(preferred_amount: 1.23))
  }

  let(:shipping_methods) {
    [free_shipping_with_required_address, free_shipping, shipping_with_fee,
     free_shipping_without_required_address, tagged_shipping]
  }

  before do
    add_enterprise_fee enterprise_fee
    set_order order

    distributor.shipping_methods.push(shipping_methods)
  end

  context "guest checkout when distributor doesn't allow guest orders" do
    before do
      distributor.update_columns allow_guest_orders: false
      visit checkout_step_path(:details)
    end

    it "should display the checkout login page" do
      expect(page).to have_content("Ok, ready to checkout?")
      expect(page).to have_content("Login")
      expect(page).to have_no_content("Checkout as guest")
    end

    it "should show the login modal when clicking the login button" do
      click_on "Login"
      expect(page).to have_selector ".login-modal"
    end
  end

  shared_examples "when I have an out of stock product in my cart" do
    before do
      variant.update!(on_demand: false, on_hand: 0)
    end

    it "returns me to the cart with an error message" do
      visit checkout_path

      expect(page).not_to have_selector 'closing', text: "Checkout now"
      expect(page).to have_selector 'closing', text: "Your shopping cart"
      expect(page).to have_content "An item in your cart has become unavailable"
      expect(page).to have_content "Update"
    end
  end

  context "as a guest user" do
    before do
      visit checkout_path
    end

    context "actually user has an account and wants to login" do
      let(:user) { create(:user) }

      it "should redirect to '/checkout/details' when user submit the login form" do
        expect(page).to have_content("Ok, ready to checkout?")

        click_on "Login"
        within ".login-modal" do
          fill_in_and_submit_login_form(user)
        end

        expect_logged_in
        expect(page).not_to have_selector ".login-modal"
        expect_to_be_on_first_step
      end
    end

    it "should display the checkout login/guest form" do
      expect(page).to have_content distributor.name
      expect(page).to have_content("Ok, ready to checkout?")
      expect(page).to have_content("Login")
      expect(page).to have_content("Checkout as guest")
    end

    it "should display the checkout details page" do
      click_on "Checkout as guest"
      expect(page).to have_content distributor.name
      expect_to_be_on_first_step
    end

    context "when no shipping methods are available" do
      before do
        shipping_methods.each { |sm| sm.update(tag_list: "hidden") }
      end

      it "should display an error message" do
        create(:filter_shipping_methods_tag_rule,
               enterprise: distributor,
               is_default: true,
               preferred_shipping_method_tags: "hidden",
               preferred_matched_shipping_methods_visibility: 'hidden')

        visit checkout_path
        expect(page).to have_content(
          "Checkout is not possible due to absence of shipping options. " \
          "Please contact the shop owner."
        )
      end
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
      expect(page).to have_button("Next - Order summary")
    end

    context "on the 'details' step" do
      before do
        visit checkout_step_path(:details)
        click_on "Checkout as guest"
      end

      context "should show a flash message and inline error messages" do
        before do
          click_button "Next - Payment method"
        end

        it "should not display bill address phone number error message" do
          expect(page).to have_content "Saving failed, please update the highlighted fields."

          expect(page).to have_selector ".field_with_errors"
          expect(page).to have_content "can't be blank"
        end
      end

      it "should allow visit '/checkout/details'" do
        expect(page).to have_current_path("/checkout/details")
      end

      it 'does not show the save as default bill address checkbox' do
        expect(page).not_to have_content "Save as default billing address"
      end

      it 'does not show the save as default ship address checkbox' do
        choose free_shipping_with_required_address.name
        uncheck "ship_address_same_as_billing"
        expect(page).not_to have_content "Save as default shipping address"
      end

      it 'display shipping methods alphabetically' do
        shipping_methods = page.all(:field, "shipping_method_id")
          .map { |field| field.sibling("label") }.map(&:text)
        expect(shipping_methods).to eq [
          "A Free Shipping with required address", "free Shipping",
          "Local", "Shipping with Fee", "Z Free Shipping without required address"
        ]
      end

      it_behaves_like "when I have an out of stock product in my cart"
    end

    context "on the 'payment' step" do
      before do
        order.update(state: "payment")
        visit checkout_step_path(:payment)
      end

      it "should allow visit '/checkout/payment'" do
        expect(page).to have_current_path("/checkout/payment")
      end

      it_behaves_like "when I have an out of stock product in my cart"
    end

    describe "hidding a shipping method" do
      let(:user) { create(:user) }
      let(:customer) { create(:customer, user:, enterprise: distributor) }

      it "shows shipping methods allowed by the rule" do
        visit checkout_path
        click_on "Checkout as guest"

        # No rules in effect
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).to have_content tagged_shipping.name

        create(:filter_shipping_methods_tag_rule,
               enterprise: distributor,
               preferred_customer_tags: "local",
               preferred_shipping_method_tags: "local",
               preferred_matched_shipping_methods_visibility: 'visible')
        create(:filter_shipping_methods_tag_rule,
               enterprise: distributor,
               is_default: true,
               preferred_shipping_method_tags: "local",
               preferred_matched_shipping_methods_visibility: 'hidden')

        visit checkout_path

        # Default rule in effect, disallows access to 'Local'
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).not_to have_content tagged_shipping.name

        login_as(user)
        visit checkout_path

        # Default rule in still effect, disallows access to 'Local'
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).not_to have_content tagged_shipping.name

        customer.update_attribute(:tag_list, "local")
        visit checkout_path

        # #local Customer can access 'Local' shipping method
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).to have_content tagged_shipping.name
      end
    end
  end
end
