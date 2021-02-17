# frozen_string_literal: true

require 'spec_helper'

describe ProcessPaymentIntent do
  let(:service) { described_class.new }

  describe "processing a payment intent" do
    let(:customer) { create(:customer) }
    let(:order) { create(:order, customer: customer, distributor: customer.enterprise, state: "payment") }
    let!(:payment) { create(
      :payment,
      cvv_response_message: "https://stripe.com/redirect",
      response_code: "pi_123",
      order: order,
      state: "pending")
    }

    context "an invalid intent" do
      let(:invalid_intent) { "invalid" }
      let(:service) { ProcessPaymentIntent.new(invalid_intent, order) }

      it "does not complete the payment" do
        service.call!
        expect(payment.reload.state).to eq("pending")
      end
    end

    context "a valid intent" do
      let(:valid_intent) { "pi_123" }
      let(:service) { ProcessPaymentIntent.new(valid_intent, order) }

      before do
        allow(order).to receive(:deliver_order_confirmation_email)
      end

      it "completes the payment" do
        service.call!
        payment.reload
        expect(payment.state).to eq("completed")
        expect(payment.cvv_response_message).to be nil
      end

      it "completes the order" do
        service.call!
        expect(order.state).to eq("complete")
        expect(order).to have_received(:deliver_order_confirmation_email)
      end
    end
  end
end
