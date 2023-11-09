# frozen_string_literal: true

require 'spec_helper'
require 'stripe/payment_intent_validator'

module Stripe
  describe PaymentIntentValidator do
    let(:secret) { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }

    let(:payment_method) {
      create(:stripe_sca_payment_method, distributor_ids: [create(:distributor_enterprise).id],
                                         preferred_enterprise_id: create(:enterprise).id)
    }
    let(:source) {
      create(:credit_card)
    }

    before do
      Stripe.api_key = secret
    end

    describe "#call", :vcr, :stripe_version do
      let(:payment) {
        create(:payment, amount: payment_intent.amount, payment_method:,
                         response_code: payment_intent.id, source:)
      }
      let(:validator) { Stripe::PaymentIntentValidator.new(payment) }

      context "when payment intent is valid" do
        let!(:pm_card) do
          Stripe::PaymentMethod.create({
                                         type: 'card',
                                         card: {
                                           number: '4242424242424242',
                                           exp_month: 12,
                                           exp_year: 2034,
                                           cvc: '314',
                                         },
                                       })
        end

        let!(:payment_intent) do
          Stripe::PaymentIntent.create({
                                         amount: 100,
                                         currency: 'eur',
                                         payment_method: pm_card,
                                         payment_method_types: ['card'],
                                         capture_method: 'manual',
                                       })
        end

        let(:payment_intent_response_body) {
          [id: payment_intent.id, status: payment_intent.status]
        }

        before do
          Stripe::PaymentIntent.confirm(payment_intent.id)
        end

        it "returns payment intent id and does not raise" do
          expect {
            result = validator.call
            expect(result).to eq payment_intent_response_body
          }.to_not raise_error Stripe::StripeError
        end
      end

      context "when payment intent contains an error" do
        let!(:pm_card) do
          Stripe::PaymentMethod.create({
                                         type: 'card',
                                         card: {
                                           # decline code: insufficient_funds
                                           number: '4000000000009995',
                                           exp_month: 12,
                                           exp_year: 2034,
                                           cvc: '314',
                                         },
                                       })
        end

        let!(:payment_intent) do
          Stripe::PaymentIntent.create({
                                         amount: 100,
                                         currency: 'eur',
                                         payment_method: pm_card,
                                         payment_method_types: ['card'],
                                         capture_method: 'manual',
                                       })
        end

        let(:payment_intent_response_body) {
          JSON.generate(id: payment_intent_id, last_payment_error: { message: "No money" })
        }

        it "raises Stripe error with payment intent last_payment_error as message" do
          expect {
            Stripe::PaymentIntent.confirm(payment_intent.id)
          }.to raise_error Stripe::StripeError, "Your card has insufficient funds."

          expect {
            validator.call
          }.to raise_error Stripe::StripeError, "Your card has insufficient funds."
        end
      end
    end
  end
end
