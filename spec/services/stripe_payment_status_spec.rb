# frozen_string_literal: true

require 'spec_helper'

describe StripePaymentStatus do
  subject { StripePaymentStatus.new(payment) }
  let(:payment) { build(:payment) }

  describe '#stripe_status' do
    context "when the payment is not a Stripe payment or does not have a payment intent" do
      it "returns nil" do
        expect(subject.stripe_status).to be_nil
      end
    end

    context "when the payment has a payment intent" do
      before { allow(payment).to receive(:response_code) { "pi_1234" } }

      it "fetches the status with Stripe::PaymentIntentValidator" do
        expect(Stripe::PaymentIntentValidator).
          to receive_message_chain(:new, :call, :status) { true }

        subject.stripe_status
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
    context "when the payment is not a Stripe payment or does not have a payment intent" do
      it "returns false" do
        expect(subject.stripe_captured?).to eq false
      end
    end

    context "when the Stripe payment has been captured" do
      before { allow(payment).to receive(:response_code) { "pi_1234" } }

      it "returns true" do
        allow(Stripe::PaymentIntentValidator).
          to receive_message_chain(:new, :call, :status) { "succeeded" }

        expect(subject.stripe_captured?).to eq true
      end
    end
  end
end
