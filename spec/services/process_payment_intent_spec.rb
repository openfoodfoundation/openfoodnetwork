# frozen_string_literal: true

require 'spec_helper'

describe ProcessPaymentIntent do
  let(:service) { described_class.new }

  describe "processing a payment intent" do
    let(:customer) { create(:customer) }
    let(:order) { create(:order, customer: customer, distributor: customer.enterprise, state: "payment") }
    let(:payment_method) { create(:stripe_sca_payment_method) }
    let!(:payment) { create(
      :payment,
      payment_method: payment_method,
      cvv_response_message: "https://stripe.com/redirect",
      response_code: "pi_123",
      order: order,
      state: "pending")
    }
    let(:validator) { instance_double(Stripe::PaymentIntentValidator) }

    before do
      allow(Stripe::PaymentIntentValidator).to receive(:new).and_return(validator)
    end

    context "an invalid intent" do
      let(:intent) { "invalid" }
      let(:service) { ProcessPaymentIntent.new(intent, order) }

      before do
        allow(validator)
          .to receive(:call).with(intent, anything).and_raise(Stripe::StripeError, "error message")
      end

      it "returns the error message" do
        result = service.call!

        expect(result.ok?).to eq(false)
        expect(result.error).to eq("error message")
      end

      it "does not complete the payment" do
        service.call!
        expect(payment.reload.state).to eq("pending")
      end
    end

    context "a valid intent" do
      let(:intent) { "pi_123" }
      let(:service) { ProcessPaymentIntent.new(intent, order) }

      before do
        allow(order).to receive(:deliver_order_confirmation_email)
        allow(validator).to receive(:call).with(intent, anything).and_return(intent) 
      end

      it "validates the intent" do
        service.call!
        expect(validator).to have_received(:call)
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

    context "payment is in a failed state" do
      let(:intent) { "valid" }
      let(:service) { ProcessPaymentIntent.new(intent, order) }

      before do
        payment.update_attribute(:state, "failed")
        allow(validator).to receive(:call).with(intent, anything).and_return(intent)
      end

      it "does not return any error message" do
        result = service.call!

        expect(result.ok?).to eq(false)
        expect(result.error).to eq("")
      end

      it "does not complete the payment" do
        service.call!
        expect(payment.reload.state).to eq("failed")
      end
    end

    context "when the payment can't be completed" do
      let(:intent) { "pi_123" }
      let(:service) { ProcessPaymentIntent.new(intent, order, payment) }

      before do
        allow(payment).to receive(:can_complete?).and_return(false)
        allow(validator).to receive(:call).with(intent, anything).and_return(intent)
      end

      it "returns a failed result" do
        result = service.call!

        expect(result.ok?).to eq(false)
        expect(result.error).to eq(I18n.t("payment_could_not_complete"))
      end

      it "does not complete the payment" do
        service.call!
        expect(payment.reload.state).to eq("pending")
      end
    end
  end
end
