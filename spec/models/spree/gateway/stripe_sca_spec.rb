# frozen_string_literal: true

require 'spec_helper'

describe Spree::Gateway::StripeSCA, type: :model do
  let(:secret) { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }

  let(:order) { create(:order_ready_for_payment) }

  let(:year_valid) { Time.zone.now.year.next }

  let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id) }

  let(:payment) {
    create(
      :payment,
      order:,
      amount: order.total,
      payment_method: subject,
      source: credit_card,
      response_code: payment_intent.id
    )
  }

  let(:gateway_options) {
    { order_id: order.number }
  }

  before { Stripe.api_key = secret }

  let(:pm_card) do
    Stripe::PaymentMethod.create({
                                   type: 'card',
                                   card: {
                                     number: '4242424242424242',
                                     exp_month: 12,
                                     exp_year: year_valid,
                                     cvc: '314',
                                   },
                                 })
  end
  let(:payment_intent) do
    Stripe::PaymentIntent.create({
                                   amount: 1000, # given in AUD cents
                                   currency: 'aud', # AUD to match order currency
                                   payment_method: pm_card,
                                   payment_method_types: ['card'],
                                   capture_method: 'manual',
                                 })
  end

  describe "#purchase", :vcr, :stripe_version do
    # Stripe acepts amounts as positive integers representing how much to charge
    # in the smallest currency unit
    let(:capture_amount) { order.total.to_i * 100 } # order total is 10 AUD

    before do
      # confirms the payment
      Stripe::PaymentIntent.confirm(payment_intent.id)
    end

    it "completes the purchase" do
      payment

      response = subject.purchase(capture_amount, credit_card, gateway_options)
      expect(response.success?).to eq true
    end

    it "provides an error message to help developer debug" do
      response_error = subject.purchase(capture_amount, credit_card, gateway_options)

      expect(response_error.success?).to eq false
      expect(response_error.message).to eq "No pending payments"
    end
  end

  describe "#error message", :vcr, :stripe_version do
    context "when payment intent state is not in 'requires_capture' state" do
      before do
        payment
      end

      it "does not succeed if payment intent state is not requires_capture" do
        response = subject.purchase(order.total, credit_card, gateway_options)
        expect(response.success?).to eq false
        expect(response.message).to eq "Invalid payment state: requires_confirmation"
      end
    end
  end

  describe "#external_payment_url" do
    let(:redirect_double) { instance_double(Checkout::StripeRedirect) }

    it "returns nil when an order is not supplied" do
      expect(subject.external_payment_url({})).to eq nil
    end

    it "calls Checkout::StripeRedirect" do
      expect(Checkout::StripeRedirect).to receive(:new).with(subject, order) { redirect_double }
      expect(redirect_double).to receive(:path).and_return("http://stripe-test.org")

      expect(subject.external_payment_url(order:)).to eq "http://stripe-test.org"
    end
  end
end
