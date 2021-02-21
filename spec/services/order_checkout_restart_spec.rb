# frozen_string_literal: true

require 'spec_helper'

describe OrderCheckoutRestart do
  let(:order) { create(:order_with_distributor) }

  describe "#call" do
    context "when the order is already in the 'cart' state" do
      it "does nothing" do
        expect(order).to_not receive(:restart_checkout!)
        OrderCheckoutRestart.new(order).call
      end
    end

    context "when the order is in a subsequent state" do
      # 'pending' is the only shipment state possible for incomplete orders
      let!(:shipment_pending) { create(:shipment, order: order, state: 'pending') }
      let!(:payment_failed) { create(:payment, order: order, state: 'failed') }
      let!(:payment_checkout) { create(:payment, order: order, state: 'checkout') }

      before do
        order.update_attribute(:state, "payment")
      end

      context "when order ship address is nil" do
        before { order.ship_address = nil }

        it "resets the order state, and clears incomplete shipments and payments" do
          OrderCheckoutRestart.new(order).call

          expect_cart_state_and_reset_adjustments
        end
      end

      context "when order ship address is not empty" do
        before { order.ship_address = order.address_from_distributor }

        it "resets the order state, and clears incomplete shipments and payments" do
          OrderCheckoutRestart.new(order).call

          expect_cart_state_and_reset_adjustments
        end
      end

      context "when order ship address is empty" do
        before { order.ship_address = Spree::Address.default }

        it "does not reset the order state nor clears incomplete shipments and payments" do
          expect do
            OrderCheckoutRestart.new(order).call
          end.to raise_error(StateMachines::InvalidTransition)

          expect(order.state).to eq 'payment'
          expect(order.shipments.count).to eq 1
          expect(order.all_adjustments.shipping.count).to eq 0
          expect(order.payments.count).to eq 2
          expect(order.all_adjustments.payment_fee.count).to eq 2
        end
      end

      def expect_cart_state_and_reset_adjustments
        expect(order.state).to eq 'cart'
        expect(order.shipments.count).to eq 0
        expect(order.all_adjustments.shipping.count).to eq 0
        expect(order.payments.count).to eq 1
        expect(order.all_adjustments.payment_fee.count).to eq 1
      end
    end
  end
end
