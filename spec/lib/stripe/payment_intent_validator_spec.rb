# frozen_string_literal: true

require 'spec_helper'
require 'stripe/payment_intent_validator'

module Stripe
  describe PaymentIntentValidator do
    describe "#call" do
      let(:validator) { Stripe::PaymentIntentValidator.new(payment) }
      let(:payment) { build(:payment, response_code: payment_intent_id) }
      let(:payment_intent_id) { "pi_123" }
      let(:stripe_account_id) { "abc123" }
      let(:stripe_account_mock) { double(stripe_user_id: stripe_account_id) }
      let(:payment_intent_response_mock) { { status: 200, body: payment_intent_response_body } }

      before do
        Stripe.api_key = "sk_test_12345"

        allow(payment).to receive_message_chain(:payment_method, :preferred_enterprise_id) { 1 }
        allow(StripeAccount).to receive(:find_by) { stripe_account_mock }

        stub_request(:get, "https://api.stripe.com/v1/payment_intents/#{payment_intent_id}")
          .with(headers: { 'Stripe-Account' => stripe_account_id })
          .to_return(payment_intent_response_mock)
      end

      context "when payment intent is valid" do
        let(:payment_intent_response_body) {
          JSON.generate(id: payment_intent_id, status: "requires_capture")
        }

        it "returns payment intent id and does not raise" do
          expect {
            result = validator.call
            expect(result).to eq payment_intent_response_body
          }.to_not raise_error Stripe::StripeError
        end
      end

      context "when payment intent contains an error" do
        let(:payment_intent_response_body) {
          JSON.generate(id: payment_intent_id, last_payment_error: { message: "No money" })
        }

        it "raises Stripe error with payment intent last_payment_error as message" do
          expect {
            validator.call
          }.to raise_error Stripe::StripeError, "No money"
        end
      end
    end
  end
end
