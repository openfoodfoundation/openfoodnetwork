# frozen_string_literal: true

require 'spec_helper'

feature "Check out with Stripe", js: true do
  include AuthenticationHelper
  include ShopWorkflow
  include CheckoutHelper

  let(:distributor) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: [variant]) }
  let(:product) { create(:product, price: 10) }
  let(:variant) { product.variants.first }
  let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil, ship_address_id: nil) }

  let(:shipping_with_fee) { create(:shipping_method, require_ship_address: false, name: "Donkeys", calculator: Calculator::FlatRate.new(preferred_amount: 4.56)) }
  let(:free_shipping) { create(:shipping_method) }
  let!(:check_with_fee) { create(:payment_method, distributors: [distributor], calculator: Calculator::FlatRate.new(preferred_amount: 5.67)) }

  before do
    set_order order
    add_product_to_cart order, product
    distributor.shipping_methods << [shipping_with_fee, free_shipping]
  end

  context 'login in as user' do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    context "with Stripe Connect" do
      let!(:stripe_pm) do
        create(:stripe_connect_payment_method, distributors: [distributor])
      end

      let!(:saved_card) do
        create(:credit_card,
               user_id: user.id,
               month: "01",
               year: "2025",
               cc_type: "visa",
               number: "1111111111111111",
               payment_method_id: stripe_pm.id,
               gateway_customer_profile_id: "i_am_saved")
      end

      let!(:stripe_account) { create(:stripe_account, enterprise_id: distributor.id, stripe_user_id: 'some_id') }

      let(:response_mock) { { id: "ch_1234", object: "charge", amount: 2000 } }

      around do |example|
        original_stripe_connect_enabled = Spree::Config[:stripe_connect_enabled]
        example.run
        Spree::Config.set(stripe_connect_enabled: original_stripe_connect_enabled)
      end

      before do
        allow(Stripe).to receive(:api_key) { "sk_test_12345" }
        allow(Stripe).to receive(:publishable_key) { "some_key" }
        Spree::Config.set(stripe_connect_enabled: true)
        stub_request(:post, "https://api.stripe.com/v1/charges")
          .with(basic_auth: ["sk_test_12345", ""])
          .to_return(status: 200, body: JSON.generate(response_mock))

        visit checkout_path
        fill_out_form(shipping_with_fee.name, stripe_pm.name, save_default_addresses: false)
      end

      it "allows use of a saved card" do
        # shows the saved credit card dropdown
        expect(page).to have_content I18n.t("spree.checkout.payment.stripe.used_saved_card")

        # default card is selected, form element is not shown
        expect(page).to have_no_selector "#card-element.StripeElement"
        expect(page).to have_select 'selected_card', selected: "Visa x-1111 Exp:01/2025"

        # allows checkout
        place_order
        expect(page).to have_content "Your order has been processed successfully"
      end
    end
  end

  describe "using Stripe SCA" do
    let!(:stripe_account) { create(:stripe_account, enterprise: distributor) }
    let!(:stripe_sca_payment_method) {
      create(:stripe_sca_payment_method, distributors: [distributor])
    }
    let!(:shipping_method) { create(:shipping_method) }
    let(:payment_intent_id) { "pi_123" }
    let(:payment_intent_response_mock) do
      {
        status: 200, body: JSON.generate(object: "payment_intent",
                                         amount: 2000,
                                         charges: { data: [{ id: "ch_1234", amount: 2000 }] })
      }
    end
    let(:payment_intent_authorize_response_mock) do
      {
        status: 200, body: JSON.generate(id: payment_intent_id,
                                         object: "payment_intent",
                                         amount: 2000,
                                         status: "requires_capture", last_payment_error: nil,
                                         charges: { data: [{ id: "ch_1234", amount: 2000 }] })
      }
    end
    let(:hubs_payment_method_response_mock) do
      {
        status: 200,
        body: JSON.generate(id: "pm_456", customer: "cus_A123")
      }
    end

    before do
      allow(Stripe).to receive(:api_key) { "sk_test_12345" }
      allow(Stripe).to receive(:publishable_key) { "pk_test_12345" }
      Spree::Config.set(stripe_connect_enabled: true)

      stub_request(:post, "https://api.stripe.com/v1/payment_intents")
        .with(basic_auth: ["sk_test_12345", ""], body: /.*#{order.number}/)
        .to_return(payment_intent_authorize_response_mock)

      stub_request(:get, "https://api.stripe.com/v1/payment_intents/#{payment_intent_id}")
        .with(headers: { 'Stripe-Account' => 'abc123' })
        .to_return(payment_intent_authorize_response_mock)

      stub_request(:post, "https://api.stripe.com/v1/payment_intents/#{payment_intent_id}/capture")
        .with(body: { amount_to_capture: Spree::Money.new(order.total).cents },
              headers: { 'Stripe-Account' => 'abc123' })
        .to_return(payment_intent_response_mock)

      stub_request(:post, "https://api.stripe.com/v1/payment_methods")
        .with(body: { payment_method: "pm_123" },
              headers: { 'Stripe-Account' => 'abc123' })
        .to_return(hubs_payment_method_response_mock)
    end

    context "with guest checkout" do
      it "completes checkout successfully" do
        visit checkout_path

        checkout_as_guest

        fill_out_form(
          free_shipping.name,
          stripe_sca_payment_method.name,
          save_default_addresses: false
        )

        expect(page).to have_css("input[name='cardnumber']")

        fill_in 'Card number', with: '4242424242424242'
        fill_in 'MM / YY', with: "01/#{DateTime.now.year + 1}"
        fill_in 'CVC', with: '123'

        place_order

        expect(page).to have_content "Confirmed"

        expect(order.reload.completed?).to eq true
        expect(order.payments.first.state).to eq "completed"
      end
    end
  end
end
