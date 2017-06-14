require 'spec_helper'

describe "Submitting Stripe Connect charge requests", type: :request do
  include ShopWorkflow
  include AuthenticationWorkflow

  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:enterprise) { create(:distributor_enterprise) }
  let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: order_cycle.coordinator, receiver: enterprise, incoming: false, pickup_time: "Monday")}
  let!(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 0), distributors: [enterprise]) }
  let!(:payment_method) { create(:payment_method, type: "Spree::Gateway::StripeConnect", distributors: [enterprise]) }
  let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }
  let!(:line_item) { create(:line_item, price: 12.34) }
  let!(:order) { line_item.order }
  let(:address) { create(:address) }
  let(:token) { "token123" }
  let(:params) { { format: :json, order: {
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
  end

  context "when a new card is submitted" do
    before do
      # Saves the card against the user
      stub_request(:post, "https://sk_test_123456:@api.stripe.com/v1/customers")
        .with(:body => { card: token, email: order.email})
        .to_return(status: 200, body: JSON.generate(store_response_mock))

      # Requests a token from the newly saved card
      stub_request(:post, "https://api.stripe.com/v1/tokens")
        .with(:body => { card: "card_XyZ456", customer: "cus_A123"})
        .to_return(status: 200, body: JSON.generate({id: "newtoken_123"}))

      # Charges the card
      stub_request(:post, "https://sk_test_123456:@api.stripe.com/v1/charges")
        .with(:body => {"amount"=>"1234", "card"=>"newtoken_123", "currency"=>"aud", "description"=>"Spree Order ID: #{order.number}", "payment_user_agent"=>"Stripe/v1 ActiveMerchantBindings/1.63.0"})
        .to_return(body: JSON.generate(charge_response_mock))
    end

    context "and the store and charge requests are accepted" do
      let(:store_response_mock) { { id: "cus_A123", default_card: "card_XyZ456", sources: { data: [{id: "1"}] } } }
      let(:charge_response_mock) { { id: "ch_1234", object: "charge", amount: 2000} }

      it "should process the payment, and stores the card/customer details" do
        put update_checkout_path, params
        json_response = JSON.parse(response.body)
        expect(json_response["path"]).to eq spree.order_path(order)
        expect(order.payments.completed.count).to be 1
        card = order.payments.completed.first.source
        expect(card.gateway_customer_profile_id).to eq "cus_A123"
        expect(card.gateway_payment_profile_id).to eq "card_XyZ456"
      end
    end

    context "when the store request returns an error message" do
      let(:store_response_mock) { { error: { message: "Bup-bow..."} } }
      let(:charge_response_mock) { { id: "ch_1234", object: "charge", amount: 2000} }

      it "should not process the payment" do
        put update_checkout_path, params
        expect(response.status).to be 400
        json_response = JSON.parse(response.body)
        expect(json_response["flash"]["error"]).to eq I18n.t(:spree_gateway_error_flash_for_checkout, error: 'Bup-bow...')
        expect(order.payments.completed.count).to be 0
      end
    end

    context "when the charge request returns an error message" do
      let(:store_response_mock) { { id: "cus_A123", default_card: "card_XyZ456", sources: { data: [{id: "1"}] } } }
      let(:charge_response_mock) { { error: { message: "Bup-bow..."} } }

      it "should not process the payment" do
        put update_checkout_path, params
        expect(response.status).to be 400
        json_response = JSON.parse(response.body)
        expect(json_response["flash"]["error"]).to eq I18n.t(:payment_processing_failed)
        expect(order.payments.completed.count).to be 0
      end
    end
  end

  context "when an existing card is submitted" do
    let(:credit_card) { create(:credit_card,
      payment_method_id: payment_method.id,
      user_id: order.user_id,
      gateway_payment_profile_id: "card_AbC123",
      gateway_customer_profile_id: "cus_Z456",
      month: 11, year: 2026) }

    before do
      params[:order][:existing_card] = credit_card.id
      quick_login_as(order.user)

      # Requests a token
      stub_request(:post, "https://api.stripe.com/v1/tokens")
        .with(:body => {"card"=>"card_AbC123", "customer"=>"cus_Z456"})
        .to_return(status: 200, body: JSON.generate({id: "newtoken_123"}), headers: {})

      # Charges the card
      stub_request(:post, "https://sk_test_123456:@api.stripe.com/v1/charges")
        .with(:body => {"amount"=>"1234", "card"=>"newtoken_123", "currency"=>"aud", "description"=>"Spree Order ID: #{order.number}", "payment_user_agent"=>"Stripe/v1 ActiveMerchantBindings/1.63.0"})
        .to_return(body: JSON.generate(charge_response_mock))
    end

    context "and the charge request is accepted" do
      let(:charge_response_mock) { { id: "ch_1234", object: "charge", amount: 2000} }

      it "should process the payment, and keep the profile ids" do
        put update_checkout_path, params
        json_response = JSON.parse(response.body)
        expect(json_response["path"]).to eq spree.order_path(order)
        expect(order.payments.completed.count).to be 1
        card = order.payments.completed.first.source
        expect(card.gateway_customer_profile_id).to eq "cus_Z456"
        expect(card.gateway_payment_profile_id).to eq "card_AbC123"
      end
    end

    context "when the charge request returns an error message" do
      let(:charge_response_mock) { { error: { message: "Bup-bow..."} } }

      it "should not process the payment" do
        put update_checkout_path, params
        expect(response.status).to be 400
        json_response = JSON.parse(response.body)
        expect(json_response["flash"]["error"]).to eq I18n.t(:payment_processing_failed)
        expect(order.payments.completed.count).to be 0
      end
    end
  end
end
