require 'spec_helper'

describe "Submitting Stripe Connect charge requests", type: :request do
  include ShopWorkflow

  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:enterprise) { create(:distributor_enterprise) }
  let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: order_cycle.coordinator, receiver: enterprise, incoming: false, pickup_time: "Monday")}
  let!(:shipping_method) { create(:shipping_method, distributors: [enterprise] ) }
  let!(:payment_method) { create(:payment_method, type: "Spree::Gateway::StripeConnect", distributors: [enterprise]) }
  let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }
  let!(:line_item) { create(:line_item, price: 12.34) }
  let!(:order) { line_item.order }
  let(:address) { create(:address) }
  let(:token) { "token123" }
  let(:params) { { order: {
      shipping_method_id: shipping_method.id,
      payments_attributes: [{payment_method_id: payment_method.id, source_attributes: { gateway_payment_profile_id: token, cc_type: "visa", last_digits: "4242", month: 7, year:2017 }}],
      bill_address_attributes: address.attributes.slice("firstname","lastname","address1","address2","phone","city","zipcode","state_id","country_id"),
      ship_address_attributes: address.attributes.slice("firstname","lastname","address1","address2","phone","city","zipcode","state_id","country_id")
  } } }

  before do
    Stripe.api_key = "sk_test_123456"
    order.update_attributes(distributor_id: enterprise.id, order_cycle_id: order_cycle.id)
    order.reload.update_totals
    set_order order
  end

  context "when the charge request is accepted" do
    let(:response_mock) { { id: "ch_1234", object: "charge", amount: 2000} }

    before do
      stub_request(:post, "https://sk_test_123456:@api.stripe.com/v1/charges")
      .with { |request| request.body.starts_with?("card=#{token}") }
      .to_return(body: JSON.generate(response_mock))
    end

    it "should process the payment" do
      put update_checkout_path, params
      expect(response).to redirect_to(spree.order_path(order))
      expect(order.payments.completed.count).to be 1
    end
  end

  context "when the charge request returns an error message" do
    let(:response_mock) { { error: { message: "Bup-bow..."} } }

    before do
      stub_request(:post, "https://sk_test_123456:@api.stripe.com/v1/charges")
      .with { |request| request.body.starts_with?("card=#{token}") }
      .to_return(body: JSON.generate(response_mock))
    end

    it "should not process the payment" do
      put update_checkout_path, params
      expect(response).to render_template(:edit)
      expect(order.payments.completed.count).to be 0
    end
  end
end
