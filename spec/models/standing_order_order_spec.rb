require 'spec_helper'

describe StandingOrderOrder, type: :model do
  describe "cancel" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:standing_order) { create(:standing_order, orders: [order]) }
    let(:standing_order_order) { standing_order.standing_order_orders.first }

    context "when the order cycle for the order is not yet closed" do
      before { order_cycle.update_attributes(orders_open_at: 1.day.ago, orders_close_at: 3.days.from_now) }

      context "and the order has already been completed" do
        let(:order) { create(:completed_order_with_totals, order_cycle: order_cycle) }

        it "sets cancelled_at to the current time, and cancels the order" do
          standing_order_order.cancel
          expect(standing_order_order.reload.cancelled_at).to be_within(5.seconds).of Time.now
          expect(order.reload.state).to eq 'canceled'
        end
      end

      context "and the order has not already been completed" do
        let(:order) { create(:order, order_cycle: order_cycle) }

        it "just sets cancelled at to the current time" do
          standing_order_order.cancel
          expect(standing_order_order.reload.cancelled_at).to be_within(5.seconds).of Time.now
          expect(order.reload.state).to eq 'cart'
        end
      end
    end

    context "when the order cycle for the order is already closed" do
      let(:order) { create(:order, order_cycle: order_cycle) }

      before { order_cycle.update_attributes(orders_open_at: 3.days.ago, orders_close_at: 1.minute.ago) }
      it "does nothing" do
        standing_order_order.cancel
        expect(standing_order_order.reload.cancelled_at).to be nil
        expect(order.reload.state).to eq 'cart'
      end
    end
  end
end
