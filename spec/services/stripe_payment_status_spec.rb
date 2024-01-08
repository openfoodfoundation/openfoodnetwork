# frozen_string_literal: true

require 'spec_helper'

describe StripePaymentStatus, :vcr, :stripe_version do
  subject { StripePaymentStatus.new(payment) }

  let(:secret) { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }

  let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id) }

  let(:payment_method) {
    create(:stripe_sca_payment_method, distributor_ids: [create(:distributor_enterprise).id],
                                       preferred_enterprise_id: create(:enterprise).id)
  }

  before { Stripe.api_key = secret }

  let(:pm_card) do
    Stripe::PaymentMethod.create({
                                   type: 'card',
                                   card: {
                                     number: '4242424242424242',
                                     exp_month: 12,
                                     exp_year: Time.zone.now.year.next,
                                     cvc: '314',
                                   },
                                 })
  end
  let(:payment_intent) do
    Stripe::PaymentIntent.create({
                                   amount: 100,
                                   currency: 'aud',
                                   payment_method: pm_card,
                                   payment_method_types: ['card'],
                                   capture_method: 'manual',
                                 })
  end

  let(:payment) {
    create(
      :payment,
      payment_method:,
      source: credit_card,
      response_code: payment_intent.id
    )
  }

  before {
    Stripe.api_key = secret
  }

  describe '#stripe_status' do
    context "when the payment is not a Stripe payment or does not have a payment intent" do
      before { payment.update!(response_code: nil) }

      it "returns nil" do
        expect(subject.stripe_status).to be_nil
      end
    end

    context "when the payment has a payment intent" do
      it "fetches the status with Stripe::PaymentIntentValidator" do
        expect(subject.stripe_status).to eq "requires_confirmation"
      end

      context "and the last action on the Stripe payment failed" do
        it "returns failed response" do
          allow(Stripe::PaymentIntentValidator).
            to receive_message_chain(:new, :call, :status).and_raise(Stripe::StripeError)

          expect(subject.stripe_status).to eq "failed"
        end
      end
    end
  end

  describe '#stripe_captured?' do
    before do
      Stripe::PaymentIntent.confirm(payment_intent.id)
      Stripe::PaymentIntent.capture(payment_intent.id)
    end

    context "when the payment is not a Stripe payment or does not have a payment intent" do
      before { payment.update!(response_code: nil) }
      it "returns false" do
        expect(subject.stripe_captured?).to eq false
      end
    end

    context "when the Stripe payment has been captured" do
      it "returns true" do
        expect(subject.stripe_captured?).to eq true
      end
    end
  end
end
