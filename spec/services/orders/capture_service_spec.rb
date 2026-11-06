# frozen_string_literal: true

RSpec.describe Orders::CaptureService do
  subject { described_class.new(order) }

  let(:order) { create(:completed_order_with_totals) }
  let(:payment) {
    create(:payment, order:, response_code: "pi_123", amount: order.total, state: "checkout")
  }

  it "captures the first pending payment" do
    allow(order).to receive(:payments).and_return([payment])

    expect(payment).to receive(:capture!).and_return(true)

    expect(subject.call).to eq(true)
  end

  context "when payment not required" do
    it "returns false" do
      allow(order).to receive(:payment_required).and_return(false)

      expect(subject.call).to eq(false)
    end
  end

  context "when no pending payment" do
    it "returns false" do
      allow(order).to receive(:payments).and_return([])

      expect(subject.call).to eq(false)
    end
  end

  context "when payment capture fails" do
    it "populates gateway_error" do
      allow(order).to receive(:payments).and_return([payment])
      expect(payment).to receive(:capture!).and_raise(Spree::Core::GatewayError)

      expect(subject.call).to eq(false)

      expect(subject.gateway_error).to be_a(Spree::Core::GatewayError)
    end
  end

  context "with pending customer credit payment" do
    let(:credit_payment) do
      Spree::Payment.create!(order: order, payment_method: Spree::PaymentMethod.customer_credit,
                             amount: 5.00, state: "checkout", skip_source_validation: true)
    end

    it "ignores the customer credit payment" do
      order.payments << credit_payment
      order.payments << payment

      expect(subject.call).to eq(true)

      expect(payment.reload.state).to eq("completed")
    end
  end

  context "with completed customer credit payment" do
    let(:credit_payment) do
      Spree::Payment.create!(order: order, payment_method: Spree::PaymentMethod.customer_credit,
                             amount: 5.00, state: "completed", skip_source_validation: true)
    end

    it "ignores the customer credit payment" do
      order.payments << credit_payment
      order.payments << payment

      expect(subject.call).to eq(true)

      expect(payment.reload.state).to eq("completed")
    end
  end
end
