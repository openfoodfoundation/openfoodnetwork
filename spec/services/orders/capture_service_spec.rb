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

  describe "with credit payments" do
    it "ignores a pending customer credit payment" do
      order.payments << create(:credit_payment, order:, state: "checkout")
      order.payments << payment

      expect(subject.call).to eq(true)

      expect(payment.reload.state).to eq("completed")
    end

    it "ignores a completed customer credit payment" do
      order.payments << create(:credit_payment, order:, state: "completed")
      order.payments << payment

      expect(subject.call).to eq(true)

      expect(payment.reload.state).to eq("completed")
    end
  end
end
