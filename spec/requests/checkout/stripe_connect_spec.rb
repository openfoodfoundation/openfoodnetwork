# frozen_string_literal: true

require 'spec_helper'

describe "checking out an order with a Stripe Connect payment method", type: :request do
  include ShopWorkflow
  include AuthenticationHelper
  include OpenFoodNetwork::ApiHelper

  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:enterprise) { create(:distributor_enterprise) }
  let!(:shipping_method) do
    create(
      :shipping_method,
      calculator: Calculator::FlatRate.new(preferred_amount: 0),
      distributors: [enterprise]
    )
  end
  let!(:payment_method) { create(:stripe_connect_payment_method, distributors: [enterprise]) }
  let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }
  let!(:line_item) { create(:line_item, price: 12.34) }
  let!(:order) { line_item.order }
  let(:address) { create(:address) }
  let(:token) { "token123" }
  let(:new_token) { "newtoken123" }
  let(:card_id) { "card_XyZ456" }
  let(:customer_id) { "cus_A123" }
  let(:payments_attributes) do
    {
      payment_method_id: payment_method.id,
      source_attributes: {
        gateway_payment_profile_id: token,
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

  before do
    order_cycle_distributed_variants = double(:order_cycle_distributed_variants)
    allow(OrderCycleDistributedVariants).to receive(:new) { order_cycle_distributed_variants }
    allow(order_cycle_distributed_variants).to receive(:distributes_order_variants?) { true }

    Stripe.api_key = "sk_test_12345"
    order.update(distributor_id: enterprise.id, order_cycle_id: order_cycle.id)
    order.reload.update_totals
    set_order order
  end

  context "when a new card is submitted" do
    let(:store_response_mock) do
      {
        status: 200,
        body: JSON.generate(
          id: customer_id,
          default_card: card_id,
          sources: { data: [{ id: "1" }] }
        )
      }
    end
    let(:token_response_mock) do
      { status: 200, body: JSON.generate(id: new_token) }
    end
    let(:charge_response_mock) do
      { status: 200, body: JSON.generate(id: "ch_1234", object: "charge", amount: 2000) }
    end

    context "and the user doesn't request that the card is saved for later" do
      before do
        # Charges the card
        stub_request(:post, "https://api.stripe.com/v1/charges")
          .with(basic_auth: ["sk_test_12345", ""], body: /#{token}.*#{order.number}/)
          .to_return(charge_response_mock)
      end

      context "and the charge request is successful" do
        it "should process the payment without storing card details" do
          put update_checkout_path, params: params

          expect(json_response["path"]).to eq order_path(order)
          expect(order.payments.completed.count).to be 1

          card = order.payments.completed.first.source

          expect(card.gateway_customer_profile_id).to eq nil
          expect(card.gateway_payment_profile_id).to eq token
          expect(card.cc_type).to eq "visa"
          expect(card.last_digits).to eq "4242"
          expect(card.first_name).to eq "Jill"
          expect(card.last_name).to eq "Jeffreys"
        end
      end

      context "when the charge request returns an error message" do
        let(:charge_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "charge-failure" }) }
        end

        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"]).to eq "charge-failure"
          expect(order.payments.completed.count).to be 0
        end
      end
    end

    context "and the customer requests that the card is saved for later" do
      before do
        source_attributes = params[:order][:payments_attributes][0][:source_attributes]
        source_attributes[:save_requested_by_customer] = '1'

        # Saves the card against the user
        stub_request(:post, "https://api.stripe.com/v1/customers")
          .with(basic_auth: ["sk_test_12345", ""], body: { card: token, email: order.email })
          .to_return(store_response_mock)

        # Requests a token from the newly saved card
        stub_request(:post, "https://api.stripe.com/v1/tokens")
          .with(body: { card: card_id, customer: customer_id })
          .to_return(token_response_mock)

        # Charges the card
        stub_request(:post, "https://api.stripe.com/v1/charges")
          .with(
            basic_auth: ["sk_test_12345", ""],
            body: /#{token}.*#{order.number}/
          ).to_return(charge_response_mock)
      end

      context "and the store, token and charge requests are successful" do
        it "should process the payment, and stores the card/customer details" do
          put update_checkout_path, params: params

          expect(json_response["path"]).to eq order_path(order)
          expect(order.payments.completed.count).to be 1

          card = order.payments.completed.first.source

          expect(card.gateway_customer_profile_id).to eq customer_id
          expect(card.gateway_payment_profile_id).to eq card_id
          expect(card.cc_type).to eq "visa"
          expect(card.last_digits).to eq "4242"
          expect(card.first_name).to eq "Jill"
          expect(card.last_name).to eq "Jeffreys"
        end
      end

      context "when the store request returns an error message" do
        let(:store_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "store-failure" }) }
        end

        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"])
            .to eq(I18n.t(:spree_gateway_error_flash_for_checkout, error: 'store-failure'))
          expect(order.payments.completed.count).to be 0
        end
      end

      context "when the charge request returns an error message" do
        let(:charge_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "charge-failure" }) }
        end

        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"]).to eq "charge-failure"
          expect(order.payments.completed.count).to be 0
        end
      end

      context "when the token request returns an error message" do
        let(:token_response_mock) do
          { status: 402, body: JSON.generate(error: { message: "token-failure" }) }
        end

        # Note, no requests have been stubbed
        it "should not process the payment" do
          put update_checkout_path, params: params

          expect(response.status).to be 400

          expect(json_response["flash"]["error"]).to eq "token-failure"
          expect(order.payments.completed.count).to be 0
        end
      end
    end
  end

  context "when an existing card is submitted" do
    let(:credit_card) do
      create(
        :credit_card,
        user_id: order.user_id,
        gateway_payment_profile_id: card_id,
        gateway_customer_profile_id: customer_id,
        last_digits: "4321",
        cc_type: "master",
        first_name: "Sammy",
        last_name: "Signpost",
        month: 11, year: 2026
      )
    end

    let(:token_response_mock) { { status: 200, body: JSON.generate(id: new_token) } }
    let(:charge_response_mock) do
      { status: 200, body: JSON.generate(id: "ch_1234", object: "charge", amount: 2000) }
    end

    before do
      params[:order][:existing_card_id] = credit_card.id
      login_as(order.user)

      # Requests a token
      stub_request(:post, "https://api.stripe.com/v1/tokens")
        .with(body: { "card" => card_id, "customer" => customer_id })
        .to_return(token_response_mock)

      # Charges the card
      stub_request(:post, "https://api.stripe.com/v1/charges")
        .with(basic_auth: ["sk_test_12345", ""], body: /#{token}.*#{order.number}/)
        .to_return(charge_response_mock)
    end

    context "and the charge and token requests are accepted" do
      it "should process the payment, and keep the profile ids and other card details" do
        put update_checkout_path, params: params

        expect(json_response["path"]).to eq order_path(order)
        expect(order.payments.completed.count).to be 1

        card = order.payments.completed.first.source

        expect(card.gateway_customer_profile_id).to eq customer_id
        expect(card.gateway_payment_profile_id).to eq card_id
        expect(card.cc_type).to eq "master"
        expect(card.last_digits).to eq "4321"
        expect(card.first_name).to eq "Sammy"
        expect(card.last_name).to eq "Signpost"
      end
    end

    context "when the charge request returns an error message" do
      let(:charge_response_mock) do
        { status: 402, body: JSON.generate(error: { message: "charge-failure" }) }
      end

      it "should not process the payment" do
        put update_checkout_path, params: params

        expect(response.status).to be 400

        expect(json_response["flash"]["error"]).to eq "charge-failure"
        expect(order.payments.completed.count).to be 0
      end
    end

    context "when the token request returns an error message" do
      let(:token_response_mock) do
        { status: 402, body: JSON.generate(error: { message: "token-error" }) }
      end

      it "should not process the payment" do
        put update_checkout_path, params: params

        expect(response.status).to be 400

        expect(json_response["flash"]["error"]).to eq "token-error"
        expect(order.payments.completed.count).to be 0
      end
    end
  end
end
