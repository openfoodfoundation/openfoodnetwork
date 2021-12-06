# frozen_string_literal: true

require 'spec_helper'

describe Spree::Gateway::StripeSCA, type: :model do
  before { Stripe.api_key = "sk_test_12345" }

  let(:order) { create(:order_with_totals_and_distribution) }
  let(:credit_card) { create(:credit_card) }
  let(:payment) {
    create(
      :payment,
      state: "checkout",
      order: order,
      amount: order.total,
      payment_method: subject,
      source: credit_card,
      response_code: "12345"
    )
  }
  let(:gateway_options) {
    { order_id: order.number }
  }
  let(:payment_authorised) {
    payment_intent(payment.amount, "requires_capture")
  }
  let(:capture_successful) {
    payment_intent(payment.amount, "succeeded")
  }

  describe "#purchase" do
    it "captures the payment" do
      stub_request(:get, "https://api.stripe.com/v1/payment_intents/12345").
        to_return(status: 200, body: payment_authorised)
      stub_request(:post, "https://api.stripe.com/v1/payment_intents/12345/capture").
        with(body: { "amount_to_capture" => order.total }).
        to_return(status: 200, body: capture_successful)

      response = subject.purchase(order.total, credit_card, gateway_options)

      expect(response.success?).to eq true
    end

    it "provides an error message to help developer debug" do
      stub_request(:get, "https://api.stripe.com/v1/payment_intents/12345").
        to_return(status: 200, body: capture_successful)

      response = subject.purchase(order.total, credit_card, gateway_options)

      expect(response.success?).to eq false
      expect(response.message).to eq "Invalid payment state: succeeded"
    end

    context "when payment intent state is not in 'requires_capture' state" do
      before do
        payment
      end

      it "succeeds if payment intent state is requires_capture" do
        stub_request(:post, "https://api.stripe.com/v1/payment_intents/12345/capture").
          with(body: { "amount_to_capture" => order.total }).
          to_return(status: 200, body: capture_successful)

        allow(Stripe::PaymentIntentValidator).to receive_message_chain(:new, :call).
          and_return(double(status: "requires_capture"))

        response = subject.purchase(order.total, credit_card, gateway_options)

        expect(response.success?).to eq true
      end

      it "does not succeed if payment intent state is not requires_capture" do
        allow(Stripe::PaymentIntentValidator).to receive_message_chain(:new, :call).
          and_return(double(status: "not_ready_yet"))

        response = subject.purchase(order.total, credit_card, gateway_options)

        expect(response.success?).to eq false
        expect(response.message).to eq "Invalid payment state: not_ready_yet"
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

      expect(subject.external_payment_url(order: order)).to eq "http://stripe-test.org"
    end
  end

  private

  def payment_intent(amount, status)
    JSON.generate(
      object: "payment_intent",
      amount: amount,
      status: status,
      charges: { data: [{ id: "ch_1234", amount: amount }] }
    )
  end
end
