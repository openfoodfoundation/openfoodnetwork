# frozen_string_literal: true

require 'stripe/payment_intent_validator'

RSpec.describe Stripe::PaymentIntentValidator do
  # These are test payment method IDs, recognised by Stripe for testing purposes.
  # See Cards By Brand > PaymentMethods here: https://docs.stripe.com/testing?testing-method=payment-methods#cards
  # We do not send raw card numbers to the API.

  self::VALID_NON_3DS_TEST_PAYMENT_METHODS = {
    "pm_card_visa" => "Visa",
    "pm_card_visa_debit" => "Visa (debit)",
    "pm_card_mastercard" => "Mastercard",
    "pm_card_mastercard_debit" => "Mastercard (debit)",
    "pm_card_mastercard_prepaid" => "Mastercard (prepaid)",
    "pm_card_amex" => "American Express",
    "pm_card_discover" => "Discover",
    "pm_card_diners" => "Diners Club",
    "pm_card_jcb" => "JCB",
    "pm_card_unionpay" => "UnionPay"
  }.freeze

  self::VALID_3DS_TEST_PAYMENT_METHODS = {
    "pm_card_authenticationRequiredOnSetup" => "Authenticate unless set up",
    "pm_card_authenticationRequired" => "Always authenticate",
    "pm_card_authenticationRequiredSetupForOffSession" => "Already set up",
    "pm_card_authenticationRequiredChargeDeclinedInsufficientFunds" => "Insufficient funds"
  }.freeze

  self::INVALID_TEST_PAYMENT_METHODS = {
    "pm_card_visa_chargeDeclined" => {
      type: "Generic decline",
      message: "Your card was declined."
    },
    "pm_card_visa_chargeDeclinedInsufficientFunds" => {
      type: "Insufficient funds decline",
      message: "Your card has insufficient funds."
    },
    "pm_card_visa_chargeDeclinedLostCard" => {
      type: "Lost card decline",
      message: "Your card was declined."
    },
    "pm_card_visa_chargeDeclinedStolenCard" => {
      type: "Stolen card decline",
      message: "Your card was declined."
    },
    "pm_card_chargeDeclinedExpiredCard" => {
      type: "Expired card decline",
      message: "Your card has expired."
    },
    "pm_card_chargeDeclinedIncorrectCvc" => {
      type: "Incorrect CVC decline",
      message: "Your card's security code is incorrect."
    },
    "pm_card_chargeDeclinedProcessingError" => {
      type: "Processing error decline",
      message: "An error occurred while processing your card. Try again in a little bit."
    },
    "pm_card_visa_chargeDeclinedVelocityLimitExceeded" => {
      type: "Exceeding velocity limit decline",
      message: %(Your card was declined for making repeated attempts too frequently
        or exceeding its amount limit.).squish
    }
  }.freeze

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
        self::VALID_NON_3DS_TEST_PAYMENT_METHODS.each do |payment_method_id, card_type|
          context "from #{card_type}" do
            let!(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: payment_method_id,
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

        self::VALID_3DS_TEST_PAYMENT_METHODS.each_key do |payment_method_id|
          xcontext "from 3D card #{payment_method_id}" do
            pending("updating spec to handle 3D2S cards")

            it "is correctly handled"
          end
        end
      end

      context "when payment intent is invalid" do
        self::INVALID_TEST_PAYMENT_METHODS.each do |payment_method_id, error|
          context "from #{error[:type]}" do
            let(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: payment_method_id,
                                             payment_method_types: ['card'],
                                             capture_method: 'manual',
                                           })
            end
            it "raises Stripe error with payment intent last_payment_error as message" do
              expect {
                Stripe::PaymentIntent.confirm(payment_intent.id)
              }.to raise_error Stripe::StripeError, error[:message]
            end
          end
        end
      end
    end

    describe "as a Stripe customer" do
      context "when payment intent is valid" do
        let(:customer_id) { customer.id }
        let(:customer) do
          Stripe::Customer.create({
                                    name: 'Apple Customer',
                                    email: 'applecustomer@example.com',
                                  })
        end

        self::VALID_NON_3DS_TEST_PAYMENT_METHODS.each do |payment_method_id, card_type|
          context "from #{card_type}" do
            let!(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: payment_method_id,
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

        self::VALID_3DS_TEST_PAYMENT_METHODS.each_key do |payment_method_id|
          xcontext "from 3D card #{payment_method_id}" do
            pending("updating spec to handle 3D2S cards")

            it "is correctly handled"
          end
        end
      end
      context "when payment intent is invalid" do
        let(:customer_id) { customer.id }
        let(:customer) do
          Stripe::Customer.create({
                                    name: 'Apple Customer',
                                    email: 'applecustomer@example.com',
                                  })
        end

        self::INVALID_TEST_PAYMENT_METHODS.each do |payment_method_id, error|
          context "from #{error[:type]}" do
            let(:payment_intent) do
              Stripe::PaymentIntent.create({
                                             amount: 100,
                                             currency: 'eur',
                                             payment_method: payment_method_id,
                                             payment_method_types: ['card'],
                                             capture_method: 'manual',
                                             customer: customer.id,
                                             setup_future_usage: "off_session"
                                           })
            end
            it "raises Stripe error with payment intent last_payment_error as message" do
              expect {
                Stripe::PaymentIntent.confirm(payment_intent.id)
              }.to raise_error Stripe::StripeError, error[:message]
            end
          end
        end
      end
    end
  end
end
