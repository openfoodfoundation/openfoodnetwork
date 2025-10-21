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
    let(:payment) {
      create(:payment, amount: payment_intent.amount, payment_method:,
                       response_code: payment_intent.id, source: pm_card)
    }
    let(:validator) { Stripe::PaymentIntentValidator.new(payment) }

    describe "as a guest" do
      context "when payment intent is valid" do
        shared_examples "payments intents" do |card_type, card_number|
          context "from #{card_type}" do
            let!(:pm_card) do
              Stripe::PaymentMethod.create({
                                             type: 'card',
                                             card: {
                                               number: card_number,
                                               exp_month: 12,
                                               exp_year: year_valid,
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
                expect(result).to eq(
                  "this doesn't affect the spec because it never runs, due to a previous error." \
                  "Yet, since this is wrapper in a negative raise_error block, it still passes"
                )
              }.not_to raise_error Stripe::StripeError
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
          it_behaves_like "payments intents", "Visa", 4_242_424_242_424_242
          it_behaves_like "payments intents", "Visa (debit)", 4_000_056_655_665_556
          it_behaves_like "payments intents", "Mastercard", 5_555_555_555_554_444
          it_behaves_like "payments intents", "Mastercard (2-series)", 2_223_003_122_003_222
          it_behaves_like "payments intents", "Mastercard (debit)", 5_200_828_282_828_210
          it_behaves_like "payments intents", "Mastercard (prepaid)", 5_105_105_105_105_100
          it_behaves_like "payments intents", "American Express",  378_282_246_310_005
          it_behaves_like "payments intents", "American Express",  371_449_635_398_431
          it_behaves_like "payments intents", "Discover", 6_011_111_111_111_117
          it_behaves_like "payments intents", "Discover", 6_011_000_990_139_424
          it_behaves_like "payments intents", "Discover (debit)", 6_011_981_111_111_113
          it_behaves_like "payments intents", "Diners Club", 3_056_930_009_020_004
          it_behaves_like "payments intents", "Diners Club (14-digit card)", 36_227_206_271_667
          it_behaves_like "payments intents", "BCcard and DinaCard", 6_555_900_000_604_105
          it_behaves_like "payments intents", "JCB", 3_566_002_020_360_505
          it_behaves_like "payments intents", "UnionPay", 6_200_000_000_000_005
          it_behaves_like "payments intents", "UnionPay (19-digit card)", 6_205_500_000_000_000_004
        end

        xcontext "valid 3D cards are correctly handled" do
          pending("updating spec to handle 3D2S cards")
          it_behaves_like "payments intents", "UnionPay (debit)", 6_200_000_000_000_047
        end
      end
      context "when payment intent is invalid" do
        shared_examples "payments intents" do |card_type, card_number, error_message|
          context "from #{card_type}" do
            let!(:pm_card) do
              Stripe::PaymentMethod.create({
                                             type: 'card',
                                             card: {
                                               number: card_number,
                                               exp_month: 12,
                                               exp_year: year_valid,
                                               cvc: '314',
                                             },
                                           })
            end
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
          it_behaves_like "payments intents", "Generic decline", 4_000_000_000_000_002,
                          "Your card was declined."
          it_behaves_like "payments intents", "Insufficient funds decline", 4_000_000_000_009_995,
                          "Your card has insufficient funds."
          it_behaves_like "payments intents", "Lost card decline", 4_000_000_000_009_987,
                          "Your card was declined."
          it_behaves_like "payments intents", "Stolen card decline", 4_000_000_000_009_979,
                          "Your card was declined."
          it_behaves_like "payments intents", "Expired card decline", 4_000_000_000_000_069,
                          "Your card has expired."
          it_behaves_like "payments intents", "Incorrect CVC decline", 4_000_000_000_000_127,
                          "Your card's security code is incorrect."
          it_behaves_like "payments intents", "Processing error decline", 4_000_000_000_000_119,
                          "An error occurred while processing your card. Try again in a little bit."
          it_behaves_like "payments intents", "Exceeding velocity limit decline",
                          4_000_000_000_006_975,
                          %(Your card was declined for making repeated attempts too frequently
            or exceeding its amount limit.).squish
        end
      end
    end

    describe "as a Stripe customer" do
      context "when payment intent is valid" do
        let(:payment_method_id) { pm_card.id }
        let(:customer_id) { customer.id }
        let!(:user) { create(:user, email: "apple.customer@example.com") }
        let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id, user:) }
        let(:customer) do
          Stripe::Customer.create({
                                    name: 'Apple Customer',
                                    email: 'applecustomer@example.com',
                                  })
        end

        shared_examples "payments intents" do |card_type, card_number|
          context "from #{card_type}" do
            let!(:pm_card) do
              Stripe::PaymentMethod.create({
                                             type: 'card',
                                             card: {
                                               number: card_number,
                                               exp_month: 12,
                                               exp_year: year_valid,
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
                                             customer: customer.id,
                                             setup_future_usage: "off_session"
                                           })
            end
            let(:payment_intent_response_body) {
              [id: payment_intent.id, status: payment_intent.status]
            }

            before do
              credit_card.update_attribute :gateway_customer_profile_id, customer_id
              Stripe::PaymentIntent.confirm(payment_intent.id)
            end
            it "returns payment intent id and does not raise" do
              expect {
                result = validator.call
                expect(result).to eq(
                  "this doesn't affect the spec because it never runs, due to a previous error." \
                  "Yet, since this is wrapper in a negative raise_error block, it still passes"
                )
              }.not_to raise_error Stripe::StripeError
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
          it_behaves_like "payments intents", "Visa", 4_242_424_242_424_242
          it_behaves_like "payments intents", "Visa (debit)", 4_000_056_655_665_556
          it_behaves_like "payments intents", "Mastercard", 5_555_555_555_554_444
          it_behaves_like "payments intents", "Mastercard (2-series)", 2_223_003_122_003_222
          it_behaves_like "payments intents", "Mastercard (debit)", 5_200_828_282_828_210
          it_behaves_like "payments intents", "Mastercard (prepaid)", 5_105_105_105_105_100
          it_behaves_like "payments intents", "American Express",  378_282_246_310_005
          it_behaves_like "payments intents", "American Express",  371_449_635_398_431
          it_behaves_like "payments intents", "Discover", 6_011_111_111_111_117
          it_behaves_like "payments intents", "Discover", 6_011_000_990_139_424
          it_behaves_like "payments intents", "Discover (debit)", 6_011_981_111_111_113
          it_behaves_like "payments intents", "Diners Club", 3_056_930_009_020_004
          it_behaves_like "payments intents", "Diners Club (14-digit card)", 36_227_206_271_667
          it_behaves_like "payments intents", "BCcard and DinaCard", 6_555_900_000_604_105
          it_behaves_like "payments intents", "JCB", 3_566_002_020_360_505
          it_behaves_like "payments intents", "UnionPay", 6_200_000_000_000_005
          it_behaves_like "payments intents", "UnionPay (19-digit card)", 6_205_500_000_000_000_004
        end

        xcontext "valid 3D cards are correctly handled" do
          pending("updating spec to handle 3D2S cards")
          it_behaves_like "payments intents", "UnionPay (debit)", 6_200_000_000_000_047
        end
      end
      context "when payment intent is invalid" do
        let(:payment_method_id) { pm_card.id }
        let(:customer_id) { customer.id }
        let!(:user) { create(:user, email: "apple.customer@example.com") }
        let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id, user:) }
        let(:customer) do
          Stripe::Customer.create({
                                    name: 'Apple Customer',
                                    email: 'applecustomer@example.com',
                                  })
        end

        shared_examples "payments intents" do |card_type, card_number, error_message|
          context "from #{card_type}" do
            let!(:pm_card) do
              Stripe::PaymentMethod.create({
                                             type: 'card',
                                             card: {
                                               number: card_number,
                                               exp_month: 12,
                                               exp_year: year_valid,
                                               cvc: '314',
                                             },
                                           })
            end
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
          it_behaves_like "payments intents", "Generic decline", 4_000_000_000_000_002,
                          "Your card was declined."
          it_behaves_like "payments intents", "Insufficient funds decline", 4_000_000_000_009_995,
                          "Your card has insufficient funds."
          it_behaves_like "payments intents", "Lost card decline", 4_000_000_000_009_987,
                          "Your card was declined."
          it_behaves_like "payments intents", "Stolen card decline", 4_000_000_000_009_979,
                          "Your card was declined."
          it_behaves_like "payments intents", "Expired card decline", 4_000_000_000_000_069,
                          "Your card has expired."
          it_behaves_like "payments intents", "Incorrect CVC decline", 4_000_000_000_000_127,
                          "Your card's security code is incorrect."
          it_behaves_like "payments intents", "Processing error decline", 4_000_000_000_000_119,
                          "An error occurred while processing your card. Try again in a little bit."
          it_behaves_like "payments intents", "Exceeding velocity limit decline",
                          4_000_000_000_006_975,
                          %(Your card was declined for making repeated attempts too frequently
            or exceeding its amount limit.).squish
        end
      end
    end
  end
end
