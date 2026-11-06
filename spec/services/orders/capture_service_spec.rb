# frozen_string_literal: true

require "spec_helper"

RSpec.describe Orders::CaptureService do
  subject(:service) { described_class.new(order.reload) }

  # The order is reloaded above because the factory's `update_order!` loads the
  # payments association (empty) before these payments exist.
  let(:order) { create(:completed_order_with_totals, distributor:) }
  let(:distributor) { create(:distributor_enterprise) }

  # The credit payment must be created before any other incomplete payment:
  # creating it invalidates other incomplete non-credit payments.
  let!(:credit_payment) do
    create(
      :payment,
      order:,
      amount: order.total / 2.0,
      payment_method: Spree::PaymentMethod.customer_credit,
      source: nil
    )
  end

  describe "#call" do
    context "when the order has a customer credit payment and a check payment" do
      let!(:check_payment) do
        create(
          :payment,
          order:,
          amount: order.total / 2.0,
          payment_method: create(:payment_method, distributors: [distributor]),
          source: nil
        )
      end

      it "captures the first capturable payment and leaves the credit payment untouched" do
        expect(service.call).to be true
        expect(check_payment.reload.state).to eq("completed")
        expect(credit_payment.reload.state).to eq("checkout")
      end

      context "with completed customer credit payment" do
        let!(:credit_payment) do
          Spree::Payment.create!(order: order, payment_method: Spree::PaymentMethod.customer_credit,
                                 amount: 5.00, state: "completed", skip_source_validation: true)
        end

        it "ignores the customer credit payment" do
          expect(service.call).to eq(true)

          expect(check_payment.reload.state).to eq("completed")
          expect(credit_payment.reload.state).to eq("completed")
        end
      end
    end

    context "when the only pending payment is a customer credit payment" do
      it "returns false with error :nothing_to_capture without touching the payment" do
        expect(service.call).to be false

        expect(service.error).to eq(:nothing_to_capture)
        expect(credit_payment.reload.state).to eq("checkout")
      end
    end

    context "when there is no pending payment" do
      it "returns false with error :nothing_to_capture" do
        allow(order).to receive(:capturable_pending_payments).and_return([])

        expect(service.call).to be(false)
        expect(service.error).to eq(:nothing_to_capture)
      end
    end

    context "when payment capture fails" do
      let(:payment) {
        create(:payment, order:, response_code: "pi_123", amount: order.total, state: "checkout")
      }
      it "populates gateway_error" do
        allow(order).to receive(:capturable_pending_payments).and_return([payment])
        expect(payment).to receive(:capture!).and_raise(Spree::Core::GatewayError)

        expect(service.call).to eq(false)

        expect(service.gateway_error).to be_a(Spree::Core::GatewayError)
      end
    end
  end
end
