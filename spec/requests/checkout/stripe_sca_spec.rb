# frozen_string_literal: true

require 'spec_helper'

describe "checking out an order with a Stripe SCA payment method", type: :request do
  include ShopWorkflow
  include AuthenticationHelper
  include OpenFoodNetwork::ApiHelper
  include StripeHelper
  include StripeStubs

  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:enterprise) { create(:distributor_enterprise) }
  let!(:shipping_method) do
    create(
      :shipping_method,
      calculator: Calculator::FlatRate.new(preferred_amount: 0),
      distributors: [enterprise]
    )
  end
  let!(:payment_method) { create(:stripe_sca_payment_method, distributors: [enterprise]) }
  let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }
  let!(:line_item) { create(:line_item, price: 12.34) }
  let!(:order) { line_item.order }
  let(:address) { create(:address) }
  let(:stripe_payment_method) { "pm_123" }
  let(:customer_id) { "cus_A123" }
  let(:hubs_stripe_payment_method) { "pm_456" }
  let(:payment_intent_id) { "pi_123" }
  let(:stripe_redirect_url) { "http://stripe.com/redirect" }
  let(:payments_attributes) do
    {
      payment_method_id: payment_method.id,
      source_attributes: {
        gateway_payment_profile_id: stripe_payment_method,
        cc_type: "visa",
        last_digits: "4242",
        month: 10,
        year: 2025,
        first_name: 'Jill',
        last_name: 'Jeffreys'
      }
    }
  end
  let(:allowed_address_attributes) do
    [
      "firstname",
      "lastname",
      "address1",
      "address2",
      "phone",
      "city",
      "zipcode",
      "state_id",
      "country_id"
    ]
  end
  let(:params) do
    {
      format: :json, order: {
        shipping_method_id: shipping_method.id,
        payments_attributes: [payments_attributes],
        bill_address_attributes: address.attributes.slice(*allowed_address_attributes),
        ship_address_attributes: address.attributes.slice(*allowed_address_attributes)
      }
    }
  end
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

  before do
    order_cycle_distributed_variants = double(:order_cycle_distributed_variants)
    allow(OrderCycleDistributedVariants).to receive(:new) { order_cycle_distributed_variants }
    allow(order_cycle_distributed_variants).to receive(:distributes_order_variants?) { true }
    allow(Stripe).to receive(:publishable_key).and_return("some_token")
    allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(true)
    Stripe.api_key = "sk_test_12345"
    order.update(distributor_id: enterprise.id, order_cycle_id: order_cycle.id)
    order.reload.update_totals
    set_order order

    # Authorizes the payment
    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .with(basic_auth: ["sk_test_12345", ""], body: /.*#{order.number}/)
      .to_return(payment_intent_authorize_response_mock)

    # Retrieves payment intent info
    stub_request(:get, "https://api.stripe.com/v1/payment_intents/#{payment_intent_id}")
      .with(headers: { 'Stripe-Account' => 'abc123' })
      .to_return(payment_intent_authorize_response_mock)

    # Captures the payment
    stub_request(:post, "https://api.stripe.com/v1/payment_intents/#{payment_intent_id}/capture")
      .with(basic_auth: ["sk_test_12345", ""], body: { amount_to_capture: "1234" })
      .to_return(payment_intent_response_mock)

    stub_retrieve_payment_method_request("pm_123")
    stub_list_customers_request(email: order.user.email, response: {})
    stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
    stub_add_metadata_request(payment_method: "pm_456", response: {})
  end

  pending "when the user submits a new card and doesn't request that the card is saved for later" do
    let(:hubs_payment_method_response_mock) do
      { status: 200, body: JSON.generate(id: hubs_stripe_payment_method) }
    end

    before do
      # Clones the payment method to the hub's stripe account
      stub_request(:post, "https://api.stripe.com/v1/payment_methods")
        .with(body: { payment_method: stripe_payment_method },
              headers: { 'Stripe-Account' => 'abc123' })
        .to_return(hubs_payment_method_response_mock)
    end

    context "and the payment intent request is successful" do
      it "should process the payment without storing card details" do
        put update_checkout_path, params: params

        expect(json_response["path"]).to eq order_path(order, order_token: order.token)
        expect(order.payments.completed.count).to be 1

        card = order.payments.completed.first.source

        expect(card.gateway_customer_profile_id).to eq nil
        expect(card.gateway_payment_profile_id).to eq stripe_payment_method
        expect(card.cc_type).to eq "visa"
        expect(card.last_digits).to eq "4242"
        expect(card.first_name).to eq "Jill"
        expect(card.last_name).to eq "Jeffreys"
      end
    end

    context "when the payment intent request returns an error message" do
      let(:payment_intent_response_mock) do
        { status: 402, body: JSON.generate(error: { message: "payment-intent-failure" }) }
      end

      it "should not process the payment" do
        put update_checkout_path, params: params

        expect(response.status).to be 400

        expect(json_response["flash"]["error"]).to eq "payment-intent-failure"
        expect(order.payments.completed.count).to be 0
      end
    end
  end

  pending "when saving a card or using a stored card is involved" do
    let(:hubs_payment_method_response_mock) do
      {
        status: 200,
        body: JSON.generate(id: hubs_stripe_payment_method, customer: customer_id)
      }
    end
    let(:customer_response_mock) do
      {
        status: 200,
        body: JSON.generate(id: customer_id, sources: { data: [{ id: "1" }] })
      }
    end

    before do
      # Clones the payment method to the hub's stripe account
      stub_request(:post, "https://api.stripe.com/v1/payment_methods")
        .with(body: { customer: customer_id, payment_method: stripe_payment_method },
              headers: { 'Stripe-Account' => 'abc123' })
        .to_return(hubs_payment_method_response_mock)

      # Creates a customer
      #   This stubs the customers call to both the main stripe account and the connected account
      stub_request(:post, "https://api.stripe.com/v1/customers")
        .with(body: { email: order.email })
        .to_return(customer_response_mock)

      # Attaches the payment method to the customer in the hub's stripe account
      stub_request(:post,
                   "https://api.stripe.com/v1/payment_methods/#{hubs_stripe_payment_method}/attach")
        .with(body: { customer: customer_id },
              headers: { 'Stripe-Account' => 'abc123' })
        .to_return(hubs_payment_method_response_mock)
    end

    context "when the user submits a new card and requests that the card is saved for later" do
      let(:payment_method_attach_response_mock) do
        {
          status: 200,
          body: JSON.generate(id: stripe_payment_method, customer: customer_id)
        }
      end

      before do
        source_attributes = params[:order][:payments_attributes][0][:source_attributes]
        source_attributes[:save_requested_by_customer] = '1'

        # Attaches the payment method to the customer
        stub_request(:post,
                     "https://api.stripe.com/v1/payment_methods/#{stripe_payment_method}/attach")
          .with(body: { customer: customer_id })
          .to_return(payment_method_attach_response_mock)
      end

      context "and the customer, payment_method and payment_intent requests are successful" do
        it "should process the payment, and store the card/customer details" do
          put update_checkout_path, params: params

          expect(json_response["path"]).to eq order_path(order, order_token: order.token)
          expect(order.payments.completed.count).to be 1

          card = order.payments.completed.first.source

          expect(card.gateway_customer_profile_id).to eq customer_id
          expect(card.gateway_payment_profile_id).to eq stripe_payment_method
          expect(card.cc_type).to eq "visa"
          expect(card.last_digits).to eq "4242"
          expect(card.first_name).to eq "Jill"
          expect(card.last_name).to eq "Jeffreys"
        end
      end

      context "when the customer request returns an error message" do
        let(:customer_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "customer-store-failure" }) }
        end

        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"])
            .to eq(format("There was a problem with your payment information: %s",
                          'customer-store-failure'))
          expect(order.payments.completed.count).to be 0
        end
      end

      context "when the payment intent request returns an error message" do
        let(:payment_intent_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "payment-intent-failure" }) }
        end

        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"]).to eq "payment-intent-failure"
          expect(order.payments.completed.count).to be 0
        end
      end

      context "when the payment_method request returns an error message" do
        let(:hubs_payment_method_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "payment-method-failure" }) }
        end

        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"]).to include "payment-method-failure"
          expect(order.payments.completed.count).to be 0
        end
      end
    end

    context "when the user selects an existing card" do
      let(:credit_card) do
        create(
          :credit_card,
          user_id: order.user_id,
          gateway_payment_profile_id: stripe_payment_method,
          gateway_customer_profile_id: customer_id,
          last_digits: "4321",
          cc_type: "master",
          first_name: "Sammy",
          last_name: "Signpost",
          month: 11, year: 2026
        )
      end

      before do
        params[:order][:existing_card_id] = credit_card.id
        login_as(order.user)
      end

      context "and the payment intent and payment method requests are accepted" do
        it "should process the payment, and keep the profile ids and other card details" do
          put update_checkout_path, params: params

          expect(json_response["path"]).to eq order_path(order, order_token: order.token)
          expect(order.payments.completed.count).to be 1

          card = order.payments.completed.first.source

          expect(card.gateway_customer_profile_id).to eq customer_id
          expect(card.gateway_payment_profile_id).to eq stripe_payment_method
          expect(card.cc_type).to eq "master"
          expect(card.last_digits).to eq "4321"
          expect(card.first_name).to eq "Sammy"
          expect(card.last_name).to eq "Signpost"
        end
      end

      context "when the payment intent request returns an error message" do
        let(:payment_intent_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "payment-intent-failure" }) }
        end

        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"]).to eq "payment-intent-failure"
          expect(order.payments.completed.count).to be 0
        end
      end

      context "when the stripe API sends a url for the authorization of the transaction" do
        let(:payment_intent_authorize_response_mock) do
          { status: 200, body: JSON.generate(id: payment_intent_id,
                                             object: "payment_intent",
                                             next_source_action: {
                                               type: "authorize_with_url",
                                               authorize_with_url: { url: stripe_redirect_url }
                                             },
                                             status: "requires_source_action") }
        end

        it "redirects the user to the authorization stripe url" do
          put update_checkout_path, params: params

          expect(response.status).to be 200
          expect(response.body).to include stripe_redirect_url
        end
      end
    end
  end
end
