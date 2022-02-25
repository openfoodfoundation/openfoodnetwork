# frozen_string_literal: true

require 'system_helper'

describe "Check out with Stripe", js: true do
  include AuthenticationHelper
  include ShopWorkflow
  include CheckoutRequestsHelper
  include StripeHelper
  include StripeStubs
  include SplitCheckoutHelper

  let(:distributor) { create(:distributor_enterprise) }
  let!(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor], variants: [variant])
  }
  let(:product) { create(:product, price: 10) }
  let(:variant) { product.variants.first }
  let(:order) {
    create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil,
                   ship_address_id: nil)
  }

  let(:shipping_with_fee) {
    create(:shipping_method, require_ship_address: false, name: "Donkeys",
                             calculator: Calculator::FlatRate.new(preferred_amount: 4.56))
  }
  let(:free_shipping) { create(:shipping_method) }
  let!(:check_with_fee) {
    create(:payment_method, distributors: [distributor],
                            calculator: Calculator::FlatRate.new(preferred_amount: 5.67))
  }


  before do
    allow(Flipper).to receive(:enabled?).with(:split_checkout).and_return(true)
    allow(Flipper).to receive(:enabled?).with(:split_checkout, anything).and_return(true)
    setup_stripe
    set_order order
    add_product_to_cart order, product
    distributor.shipping_methods << [shipping_with_fee, free_shipping]
  end

  describe "using Stripe SCA" do
    let!(:stripe_account) { create(:stripe_account, enterprise: distributor) }
    let!(:stripe_sca_payment_method) {
      create(:stripe_sca_payment_method, distributors: [distributor])
    }
    let!(:shipping_method) { create(:shipping_method) }
    let(:error_message) { "Card was declined: insufficient funds." }

    before do
      stub_payment_intent_get_request
      stub_payment_methods_post_request
    end

    context "with guest checkout" do
      before do
        stub_retrieve_payment_method_request("pm_123")
        stub_list_customers_request(email: order.user.email, response: {})
        stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
      end

      context "when the card is accepted" do
        before do
          stub_payment_intents_post_request order: order
          stub_successful_capture_request order: order
        end

        it "completes checkout successfully" do
          visit checkout_path
          checkout_as_guest
          split_checkout_with_stripe
          expect(page).to have_content "Confirmed"
          byebug
          expect(order.reload.completed?).to eq true
          expect(order.payments.first.state).to eq "completed"
        end
      end
    end

    context "with a logged in user" do
      let(:user) { order.user }

      before do
        login_as user
        stub_retrieve_payment_method_request("pm_123")
        stub_list_customers_request(email: order.user.email, response: {})
        stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
      end

      context "when the card is accepted" do
        before do
          stub_payment_intents_post_request order: order
          stub_successful_capture_request order: order
        end

        it "completes checkout successfully" do
          visit checkout_path
          split_checkout_with_stripe
          expect(page).to have_content "Confirmed"
          byebug
          expect(order.reload.completed?).to eq true
          expect(order.payments.first.state).to eq "completed"
        end
      end
    end
  end
end
