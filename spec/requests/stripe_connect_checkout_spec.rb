require 'spec_helper'

describe "Submitting Stripe Connect charge requests", type: :request do
  include ShopWorkflow

  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:enterprise) { create(:distributor_enterprise) }
  let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: order_cycle.coordinator, receiver: enterprise, incoming: false, pickup_time: "Monday")}
  let!(:shipping_method) { create(:free_shipping_method, distributors: [enterprise]) }
  let!(:payment_method) { create(:payment_method, type: "Spree::Gateway::StripeConnect", distributors: [enterprise]) }
  let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }
  let!(:line_item) { create(:line_item, price: 12.34) }
  let!(:order) { line_item.order }
  let(:address) { create(:address) }
  let(:token) { "token123" }
  let(:params) { { order: {
      shipping_method_id: shipping_method.id,
      payments_attributes: [{payment_method_id: payment_method.id, source_attributes: { gateway_payment_profile_id: token, cc_type: "visa", last_digits: "4242", month: 10, year: 2025 }}],
      bill_address_attributes: address.attributes.slice("firstname","lastname","address1","address2","phone","city","zipcode","state_id","country_id"),
      ship_address_attributes: address.attributes.slice("firstname","lastname","address1","address2","phone","city","zipcode","state_id","country_id")
  } } }

  before do
    Stripe.api_key = "sk_test_123456"
    order.update_attributes(distributor_id: enterprise.id, order_cycle_id: order_cycle.id)
    order.reload.update_totals
    set_order order

    # Storing the card against the user
    stub_request(:post, "https://sk_test_123456:@api.stripe.com/v1/customers")
      .with(:body => { card: token, email: order.email})
      .to_return(status: 200, body: JSON.generate({ id: "cus_A123", default_card: "card_XyZ456", sources: { data: [{id: "1"}] } }), headers: {})

    stub_request(:post, "https://api.stripe.com/v1/tokens")
      .with(:body => { card: "card_XyZ456", customer: "cus_A123"})
      .to_return(status: 200, body: JSON.generate({id: "tok_123"}), headers: {})

    stub_request(:post, "https://sk_test_123456:@api.stripe.com/v1/charges")
      .with(:body => {"amount"=>"1234", "card"=>{"exp_month"=>"10", "exp_year"=>"2025"}, "currency"=>"aud", "description"=>"Spree Order ID: #{order.number}", "payment_user_agent"=>"Stripe/v1 ActiveMerchantBindings/1.63.0"})
      .to_return(body: JSON.generate(charge_response_mock))
  end

  context "when the charge request is accepted" do
    let(:charge_response_mock) { { id: "ch_1234", object: "charge", amount: 2000} }

    it "should process the payment" do
      put update_checkout_path, params
      expect(response).to redirect_to(spree.order_path(order))
      expect(order.payments.completed.count).to be 1
    end
  end

  context "when the charge request returns an error message" do
    let(:charge_response_mock) { { error: { message: "Bup-bow..."} } }

    it "should not process the payment" do
      put update_checkout_path, params
      expect(response).to render_template(:edit)
      expect(order.payments.completed.count).to be 0
    end
  end
end
