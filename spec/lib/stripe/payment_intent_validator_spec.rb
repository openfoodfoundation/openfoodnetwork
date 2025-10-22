# frozen_string_literal: true

require 'spec_helper'
require 'stripe/payment_intent_validator'

RSpec.describe Stripe::PaymentIntentValidator do
  let(:payment_method) {
    create(:stripe_sca_payment_method, distributor_ids: [create(:distributor_enterprise).id],
                                       preferred_enterprise_id: create(:enterprise).id)
  }

  let(:year_valid) { Time.zone.now.year.next }

  describe "#call", :vcr, :stripe_version do
    let!(:user) { create(:user, email: "apple.customer@example.com") }
    let(:credit_card) { create(:credit_card, user:) }
    let(:payment) {
      create(:payment, amount: payment_intent.amount, payment_method:,
                       response_code: payment_intent.id, source: credit_card)
    }
    let(:validator) { Stripe::PaymentIntentValidator.new(payment) }

    describe "as a guest" do
      context "when payment intent is valid" do
        shared_examples "payments intents" do |card_type, pm_card|
          context "from #{card_type}" do
            let!(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: pm_card,
                                             payment_method_types: ['card'],
                                             capture_method: 'manual',
                                           })
            end

            before do
              Stripe::PaymentIntent.confirm(payment_intent.id)
            end
            it "returns payment intent id" do
              result = validator.call
              expect(result.id).to eq(payment_intent.id)
            end

            it "captures the payment" do
              expect(Stripe::PaymentIntent.retrieve(
                payment_intent.id
              ).status).to eq("requires_capture")

              Stripe::PaymentIntent.capture(payment_intent.id)

              expect(Stripe::PaymentIntent.retrieve(
                payment_intent.id
              ).status).to eq("succeeded")
            end
          end
        end

        context "valid non-3D credit cards are correctly handled" do
          it_behaves_like "payments intents", "Visa", "pm_card_visa"
          it_behaves_like "payments intents", "Visa (debit)", "pm_card_visa_debit"
          it_behaves_like "payments intents", "Mastercard", "pm_card_mastercard"
          it_behaves_like "payments intents", "Mastercard (debit)", "pm_card_mastercard_debit"
          it_behaves_like "payments intents", "Mastercard (prepaid)", "pm_card_mastercard_prepaid"
          it_behaves_like "payments intents", "American Express", "pm_card_amex"
          it_behaves_like "payments intents", "Discover", "pm_card_discover"
          it_behaves_like "payments intents", "Diners Club", "pm_card_diners"
          it_behaves_like "payments intents", "JCB", "pm_card_jcb"
          it_behaves_like "payments intents", "UnionPay", "pm_card_unionpay"
        end

        xcontext "valid 3D cards are correctly handled" do
          pending("updating spec to handle 3D2S cards")
          it_behaves_like "payments intents", "Authenticate unless set up",
                          "pm_card_authenticationRequiredOnSetup"
          it_behaves_like "payments intents", "Always authenticate",
                          "pm_card_authenticationRequired"
          it_behaves_like "payments intents", "Already set up",
                          "pm_card_authenticationRequiredSetupForOffSession"
          it_behaves_like "payments intents", "Insufficient funds",
                          "pm_card_authenticationRequiredChargeDeclinedInsufficientFunds"
        end
      end
      context "when payment intent is invalid" do
        shared_examples "payments intents" do |card_type, pm_card, error_message|
          context "from #{card_type}" do
            let(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: pm_card,
                                             payment_method_types: ['card'],
                                             capture_method: 'manual',
                                           })
            end
            it "raises Stripe error with payment intent last_payment_error as message" do
              expect {
                Stripe::PaymentIntent.confirm(payment_intent.id)
              }.to raise_error Stripe::StripeError, error_message
            end
          end
        end
        context "invalid credit cards are correctly handled" do
          it_behaves_like "payments intents", "Generic decline", "pm_card_visa_chargeDeclined",
                          "Your card was declined."
          it_behaves_like "payments intents", "Insufficient funds decline",
                          "pm_card_visa_chargeDeclinedInsufficientFunds",
                          "Your card has insufficient funds."
          it_behaves_like "payments intents", "Lost card decline",
                          "pm_card_visa_chargeDeclinedLostCard",
                          "Your card was declined."
          it_behaves_like "payments intents", "Stolen card decline",
                          "pm_card_visa_chargeDeclinedStolenCard",
                          "Your card was declined."
          it_behaves_like "payments intents", "Expired card decline",
                          "pm_card_chargeDeclinedExpiredCard",
                          "Your card has expired."
          it_behaves_like "payments intents", "Incorrect CVC decline",
                          "pm_card_chargeDeclinedIncorrectCvc",
                          "Your card's security code is incorrect."
          it_behaves_like "payments intents", "Processing error decline",
                          "pm_card_chargeDeclinedProcessingError",
                          "An error occurred while processing your card. Try again in a little bit."
          it_behaves_like "payments intents", "Exceeding velocity limit decline",
                          "pm_card_visa_chargeDeclinedVelocityLimitExceeded",
                          %(Your card was declined for making repeated attempts too frequently
            or exceeding its amount limit.).squish
        end
      end
    end

    describe "as a Stripe customer" do
      context "when payment intent is valid" do
        let(:payment_method_id) { pm_card.id }
        let(:customer_id) { customer.id }
        let(:customer) do
          Stripe::Customer.create({
                                    name: 'Apple Customer',
                                    email: 'applecustomer@example.com',
                                  })
        end

        shared_examples "payments intents" do |card_type, pm_card|
          context "from #{card_type}" do
            let!(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: pm_card,
                                             payment_method_types: ['card'],
                                             capture_method: 'manual',
                                             customer: customer.id,
                                             setup_future_usage: "off_session"
                                           })
            end

            before do
              Stripe::PaymentIntent.confirm(payment_intent.id)
            end
            it "returns payment intent id" do
              result = validator.call
              expect(result.id).to eq(payment_intent.id)
            end

            it "captures the payment" do
              expect(Stripe::PaymentIntent.retrieve(
                payment_intent.id
              ).status).to eq("requires_capture")

              Stripe::PaymentIntent.capture(payment_intent.id)

              expect(Stripe::PaymentIntent.retrieve(
                payment_intent.id
              ).status).to eq("succeeded")
            end
          end
        end

        context "valid non-3D credit cards are correctly handled" do
          it_behaves_like "payments intents", "Visa", "pm_card_visa"
          it_behaves_like "payments intents", "Visa (debit)", "pm_card_visa_debit"
          it_behaves_like "payments intents", "Mastercard", "pm_card_mastercard"
          it_behaves_like "payments intents", "Mastercard (debit)", "pm_card_mastercard_debit"
          it_behaves_like "payments intents", "Mastercard (prepaid)", "pm_card_mastercard_prepaid"
          it_behaves_like "payments intents", "American Express", "pm_card_amex"
          it_behaves_like "payments intents", "Discover", "pm_card_discover"
          it_behaves_like "payments intents", "Diners Club", "pm_card_diners"
          it_behaves_like "payments intents", "JCB", "pm_card_jcb"
          it_behaves_like "payments intents", "UnionPay", "pm_card_unionpay"
        end

        xcontext "valid 3D cards are correctly handled" do
          pending("updating spec to handle 3D2S cards")
          it_behaves_like "payments intents", "Authenticate unless set up",
                          "pm_card_authenticationRequiredOnSetup"
          it_behaves_like "payments intents", "Always authenticate",
                          "pm_card_authenticationRequired"
          it_behaves_like "payments intents", "Already set up",
                          "pm_card_authenticationRequiredSetupForOffSession"
          it_behaves_like "payments intents", "Insufficient funds",
                          "pm_card_authenticationRequiredChargeDeclinedInsufficientFunds"
        end
      end
      context "when payment intent is invalid" do
        let(:payment_method_id) { pm_card.id }
        let(:customer_id) { customer.id }
        let(:customer) do
          Stripe::Customer.create({
                                    name: 'Apple Customer',
                                    email: 'applecustomer@example.com',
                                  })
        end

        shared_examples "payments intents" do |card_type, pm_card, error_message|
          context "from #{card_type}" do
            let(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: pm_card,
                                             payment_method_types: ['card'],
                                             capture_method: 'manual',
                                             customer: customer.id,
                                             setup_future_usage: "off_session"
                                           })
            end
            it "raises Stripe error with payment intent last_payment_error as message" do
              expect {
                Stripe::PaymentIntent.confirm(payment_intent.id)
              }.to raise_error Stripe::StripeError, error_message
            end
          end
        end
        context "invalid credit cards are correctly handled" do
          it_behaves_like "payments intents", "Generic decline", "pm_card_visa_chargeDeclined",
                          "Your card was declined."
          it_behaves_like "payments intents", "Insufficient funds decline",
                          "pm_card_visa_chargeDeclinedInsufficientFunds",
                          "Your card has insufficient funds."
          it_behaves_like "payments intents", "Lost card decline",
                          "pm_card_visa_chargeDeclinedLostCard",
                          "Your card was declined."
          it_behaves_like "payments intents", "Stolen card decline",
                          "pm_card_visa_chargeDeclinedStolenCard",
                          "Your card was declined."
          it_behaves_like "payments intents", "Expired card decline",
                          "pm_card_chargeDeclinedExpiredCard",
                          "Your card has expired."
          it_behaves_like "payments intents", "Incorrect CVC decline",
                          "pm_card_chargeDeclinedIncorrectCvc",
                          "Your card's security code is incorrect."
          it_behaves_like "payments intents", "Processing error decline",
                          "pm_card_chargeDeclinedProcessingError",
                          "An error occurred while processing your card. Try again in a little bit."
          it_behaves_like "payments intents", "Exceeding velocity limit decline",
                          "pm_card_visa_chargeDeclinedVelocityLimitExceeded",
                          %(Your card was declined for making repeated attempts too frequently
            or exceeding its amount limit.).squish
        end
      end
    end
  end
end
