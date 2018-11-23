require 'spec_helper'

describe RestartCheckout do
  let(:order) { create(:order) }

  describe "#restart_checkout" do
    let!(:shipment_pending) { create(:shipment, order: order, state: 'pending') }
    let!(:payment_checkout) { create(:payment, order: order, state: 'checkout') }
    let!(:payment_failed) { create(:payment, order: order, state: 'failed') }

    before do
      order.update_attribute(:shipping_method_id, shipment_pending.shipping_method_id)
    end

    context "when the order is already in the 'cart' state" do
      it "does nothing" do
        expect(order).to_not receive(:restart_checkout!)
        RestartCheckout.new(order).restart_checkout
      end
    end

    context "when the order is in a subsequent state" do
      before do
        order.update_attribute(:state, "payment")
      end

      # NOTE: at the time of writing, it was not possible to create a shipment with a state other than
      # 'pending' when the order has not been completed, so this is not a case that requires testing.
      it "resets the order state, and clears incomplete shipments and payments" do
        expect(order).to receive(:restart_checkout!).and_call_original
        expect(order.shipping_method_id).to_not be nil
        expect(order.shipments.count).to be 1
        expect(order.adjustments.shipping.count).to be 1
        expect(order.payments.count).to be 2
        expect(order.adjustments.payment_fee.count).to be 2

        RestartCheckout.new(order).restart_checkout

        expect(order.reload.state).to eq 'cart'
        expect(order.shipping_method_id).to be nil
        expect(order.shipments.count).to be 0
        expect(order.adjustments.shipping.count).to be 0
        expect(order.payments.count).to be 1
        expect(order.adjustments.payment_fee.count).to be 1
      end
    end
  end
end
