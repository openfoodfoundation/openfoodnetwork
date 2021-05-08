# frozen_string_literal: true

require 'spec_helper'

module Stripe
  describe ProfileStorer do
    describe "create_customer_from_token" do
      let(:payment) { create(:payment) }
      let(:stripe_payment_method) { create(:stripe_connect_payment_method) }
      let(:profile_storer) { Stripe::ProfileStorer.new(payment, stripe_payment_method.provider) }

      let(:customer_id) { "cus_A123" }
      let(:card_id) { "card_2342" }
      let(:customer_response_mock) { { status: 200, body: customer_response_body } }

      before do
        Stripe.api_key = "sk_test_12345"

        stub_request(:post, "https://api.stripe.com/v1/customers")
          .with(basic_auth: ["sk_test_12345", ""], body: { email: payment.order.email })
          .to_return(customer_response_mock)
      end

      context "when called from Stripe Connect" do
        let(:customer_response_body) {
          JSON.generate(id: customer_id, default_card: card_id, sources: { data: [{ id: "1" }] })
        }

        it "fetches the customer id and the card id from the correct response fields" do
          profile_storer.create_customer_from_token

          expect(payment.source.gateway_customer_profile_id).to eq customer_id
          expect(payment.source.gateway_payment_profile_id).to eq card_id
        end
      end

      context "when called from Stripe SCA" do
        let(:customer_response_body) {
          JSON.generate(customer: customer_id, id: card_id, sources: { data: [{ id: "1" }] })
        }

        it "fetches the customer id and the card id from the correct response fields" do
          profile_storer.create_customer_from_token

          expect(payment.source.gateway_customer_profile_id).to eq customer_id
          expect(payment.source.gateway_payment_profile_id).to eq card_id
        end
      end
    end
  end
end
