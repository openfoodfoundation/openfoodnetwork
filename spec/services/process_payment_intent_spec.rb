# frozen_string_literal: true

require 'spec_helper'

describe ProcessPaymentIntent do
  let(:service) { described_class.new }

  describe "processing a payment intent" do
    let(:customer) { create(:customer) }
    let(:order) {
      create(:order_with_totals, customer: customer, distributor: customer.enterprise,
                                 state: "confirmation")
    }
    let(:payment_method) { create(:stripe_sca_payment_method) }

    let!(:payment) {
      create(
        :payment,
        payment_method: payment_method,
        cvv_response_message: "https://stripe.com/redirect",
        response_code: "pi_123",
        order: order,
        state: "requires_authorization"
      )
    }
    let(:validator) { instance_double(Stripe::PaymentIntentValidator) }

    before do
      allow(Stripe::PaymentIntentValidator).to receive(:new).and_return(validator)
    end

    context "with an invalid intent" do
      let(:intent) { "pi_123" }
      let(:service) { ProcessPaymentIntent.new(intent, order) }

      context "which does not match the last payment" do
        let(:intent) { "pi_456" }

        it "returns false" do
          result = service.call!

          expect(result.ok?).to eq(false)
          expect(result.error).to eq("")
        end

        it "does not complete the payment" do
          service.call!
          expect(payment.reload.state).to eq("requires_authorization")
        end
      end

      context "where the stripe payment intent validation responds with errors" do
        before do
          allow(validator).to receive(:call).
            and_raise(Stripe::StripeError, "error message")
        end

        it "returns returns the error message" do
          result = service.call!

          expect(result.ok?).to eq(false)
          expect(result.error).to eq("error message")
        end

        it "does not complete the payment" do
          service.call!
          expect(payment.reload.state).to eq("failed")
        end
      end
    end

    context "a valid intent" do
      let(:intent) { "pi_123" }
      let(:intent_response) { double(status: "requires_capture") }
      let(:service) { ProcessPaymentIntent.new(intent, order) }

      before do
        allow(order).to receive(:deliver_order_confirmation_email)
        allow(validator).to receive(:call).and_return(intent_response)
      end

      it "validates the intent" do
        expect(order).to receive(:process_payments!) { true }
        service.call!
        expect(validator).to have_received(:call)
      end

      it "processes the order's payment" do
        allow(order).to receive(:pending_payments) { [payment] }

        expect(order).to receive(:process_payments!).and_call_original
        expect(payment).to receive(:purchase!) { true }
        service.call!
      end

      context "when payment processing succeeds" do
        before do
          allow(order).to receive(:process_payments!) do
            payment.complete!
          end
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

      context "when payment processing fails" do
        before do
          allow(order).to receive(:process_payments!) do
            payment.failure!
          end
        end

        it "does not complete the payment" do
          service.call!
          payment.reload
          expect(payment.state).to eq("failed")
        end

        it "completes the order, but with failed payment state recorded" do
          service.call!
          order.reload

          expect(order.state).to eq("complete")
          expect(order.payment_state).to eq("failed")
          expect(order).to have_received(:deliver_order_confirmation_email)
        end
      end
    end

    context "payment is in a failed state" do
      let(:intent) { "valid" }
      let(:service) { ProcessPaymentIntent.new(intent, order) }

      before do
        payment.update_attribute(:state, "failed")
        allow(validator).to receive(:call).and_return(intent)
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
      let(:intent_response) { double(id: "pi_123", status: "requires_capture") }
      let(:service) { ProcessPaymentIntent.new(intent, order) }

      before do
        allow(order).to receive(:process_payments!) { nil }
        allow(validator).to receive(:call).and_return(intent_response)
      end

      it "returns a failed result" do
        result = service.call!

        expect(result.ok?).to eq(false)
        expect(result.error).to eq('The payment could not be completed')
      end

      it "does fails the payment" do
        service.call!
        expect(payment.reload.state).to eq("failed")
      end
    end
  end
end
