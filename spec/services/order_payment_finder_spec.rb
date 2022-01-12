# frozen_string_literal: true

require 'spec_helper'

describe OrderPaymentFinder do
  let(:order) { create(:order_with_distributor) }
  let(:finder) { OrderPaymentFinder.new(order) }

  context "when order has several non pending payments" do
    let!(:failed_payment) { create(:payment, order: order, state: 'failed') }
    let!(:complete_payment) { create(:payment, :completed, order: order) }

    it "#last_payment returns the last payment" do
      expect(finder.last_payment).to eq complete_payment
    end

    it "#last_pending_payment returns nil" do
      expect(finder.last_pending_payment).to be nil
    end
  end

  context "when order has a pending payment and a non pending payment" do
    let!(:processing_payment) { create(:payment, order: order, state: 'processing') }
    let!(:failed_payment) { create(:payment, order: order, state: 'failed') }

    it "#last_payment returns the last payment" do
      expect(finder.last_payment).to eq failed_payment
    end

    it "#last_pending_payment returns the pending payment" do
      # a payment in the processing state is a pending payment
      expect(finder.last_pending_payment).to eq processing_payment
    end

    context "and an extra last pending payment" do
      let!(:pending_payment) { create(:payment, order: order, state: 'pending') }

      it "#last_payment returns the last payment" do
        expect(finder.last_payment).to eq pending_payment
      end

      it "#last_pending_payment returns the pending payment" do
        expect(finder.last_pending_payment).to eq pending_payment
      end
    end
  end
end
