# frozen_string_literal: true

require 'spec_helper'

describe Checkout::PaymentMethodFetcher do
  let!(:order) { create(:completed_order_with_totals) }
  let(:payment1) { build(:payment, order: order) }
  let(:payment2) { build(:payment, order: order) }
  let(:service) { Checkout::PaymentMethodFetcher.new(order) }

  describe '#call' do
    context "when the order has payments" do
      before do
        order.payments << payment1
        order.payments << payment2
      end

      it "returns the payment_method of the most recently created payment" do
        expect(service.call).to eq payment2.payment_method
      end
    end

    context "when the order has no payments" do
      it "returns nil" do
        expect(service.call).to be_nil
      end
    end
  end
end
