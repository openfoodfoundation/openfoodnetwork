require 'spec_helper'

describe RestartCheckout do
  let(:order) { create(:order) }

  describe "#call" do
    context "when the order is already in the 'cart' state" do
      it "does nothing" do
        expect(order).to_not receive(:restart_checkout!)
        RestartCheckout.new(order).call
      end
    end

    context "when the order is in a subsequent state" do
      let!(:shipment_pending) { create(:shipment, order: order, state: 'pending') }
      let!(:payment_failed) { create(:payment, order: order, state: 'failed') }
      let!(:payment_checkout) { create(:payment, order: order, state: 'checkout') }

      before do
        order.update_attribute(:state, "payment")
      end

      # NOTE: at the time of writing, it was not possible to create a shipment
      # with a state other than 'pending' when the order has not been
      # completed, so this is not a case that requires testing.
      it "resets the order state, and clears incomplete shipments and payments" do
        RestartCheckout.new(order).call

        expect(order.state).to eq 'cart'
        expect(order.shipments.count).to eq 0
        expect(order.adjustments.shipping.count).to eq 0
        expect(order.payments.count).to eq 1
        expect(order.adjustments.payment_fee.count).to eq 1
      end
    end
  end
end
