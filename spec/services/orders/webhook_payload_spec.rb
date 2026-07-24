# frozen_string_literal: true

RSpec.describe Orders::WebhookPayload do
  describe "#to_hash" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:order) { create(:completed_order_with_totals, order_cycle:) }
    let(:payment) { create(:payment, order:) }

    subject { described_class.new(order:, payment:, enterprise: order.distributor) }

    it "returns a hash with the order, payment method and enterprise data" do
      enterprise = order.distributor

      payload = {
        order: {
          number: order.number,
          email: order.email,
          total: order.total,
          currency: order.currency,
          outstanding_balance: order.new_outstanding_balance
        },
        payment_method: {
          name: payment.payment_method.name,
          type: payment.payment_method.type
        },
        enterprise: {
          abn: enterprise.abn,
          acn: enterprise.acn,
          name: enterprise.name,
          address: {
            address1: enterprise.address.address1,
            address2: enterprise.address.address2,
            city: enterprise.address.city,
            zipcode: enterprise.address.zipcode
          }
        }
      }.with_indifferent_access

      expect(subject.to_hash).to eq(payload)
    end

    context "without a pending payment" do
      subject { described_class.new(order:, payment: nil, enterprise: order.distributor) }

      it "returns nil payment method details" do
        expect(subject.to_hash[:payment_method]).to eq(
          "name" => nil, "type" => nil
        )
      end
    end
  end
end
