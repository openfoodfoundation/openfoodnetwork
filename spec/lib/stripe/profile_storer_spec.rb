# frozen_string_literal: true

require 'spec_helper'

module Stripe
  describe ProfileStorer do
    include StripeStubs
    include StripeHelper

    describe "create_customer_from_token" do
      let(:stripe_payment_method) { create(:stripe_sca_payment_method) }
      let(:card) { create(:credit_card, gateway_payment_profile_id: card_id) }
      let(:payment) { create(:payment, source: card, payment_method: stripe_payment_method) }
      let(:profile_storer) { Stripe::ProfileStorer.new(payment, stripe_payment_method.provider) }

      let(:customer_id) { "cus_A123" }
      let(:card_id) { "card_2342" }
      let(:customer_response_mock) {
        { status: 200, body: JSON.generate(id: customer_id, sources: { data: [{ id: "1" }] }) }
      }

      around do |example|
        with_stripe_setup { example.run }
      end

      before do
        stub_customers_post_request(email: payment.order.email, response: customer_response_mock)
        stub_payment_method_attach_request(payment_method: card_id, customer: customer_id)
      end

      context "when called from Stripe SCA" do
        it "fetches the customer id and the card id from the correct response fields" do
          profile_storer.create_customer_from_token

          expect(payment.source.gateway_customer_profile_id).to eq customer_id
          expect(payment.source.gateway_payment_profile_id).to eq card_id
        end

        context "when request fails" do
          it "raises an error" do
            expect(stripe_payment_method.provider).to receive(:store).and_return(
              ActiveMerchant::Billing::Response.new(false, "some error")
            )

            expect { profile_storer.create_customer_from_token }.to raise_error(
              Spree::Core::GatewayError
            )
          end
        end
      end
    end
  end
end
