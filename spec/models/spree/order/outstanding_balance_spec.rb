require 'spec_helper'

describe Spree::Order do
  let(:order) { build(:order) }

  context "#outstanding_balance" do
    context 'when orders are in cart state' do
      before do
        create(:order, total: order_total, payment_total: 0, state: 'cart')
        create(:order, total: order_total, payment_total: 0, state: 'cart')
      end

      it 'returns the order balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(-order_total)
      end
    end

    context 'when orders are in address state' do
      before do
        create(:order, total: order_total, payment_total: 0, state: 'address')
        create(:order, total: order_total, payment_total: 50, state: 'address')
      end

      it 'returns the order balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(-order_total)
      end
    end

    context 'when orders are in delivery state' do
      before do
        create(:order, total: order_total, payment_total: 0, state: 'delivery')
        create(:order, total: order_total, payment_total: 50, state: 'delivery')
      end

      it 'returns the order balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(-order_total)
      end
    end

    context 'when orders are in payment state' do
      before do
        create(:order, total: order_total, payment_total: 0, state: 'payment')
        create(:order, total: order_total, payment_total: 50, state: 'payment')
      end

      it 'returns the order balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(-order_total)
      end
    end

    context 'when no orders where paid' do
      before do
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
      end

      it 'returns the customer balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(-order_total)
      end
    end

    context 'when an order was paid' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'complete')
      end

      it 'returns the customer balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(payment_total - 200.0)
      end
    end

    context 'when an order is canceled' do
      let(:payment_total) { order_total }
      let(:non_canceled_orders_total) { order_total }

      before do
        create(:order, total: order_total, payment_total: order_total, state: 'canceled')
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
      end

      it 'returns the customer balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(payment_total)
      end
    end

    context 'when an order is resumed' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'resumed')
      end

      it 'returns the customer balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(payment_total - 200.0)
      end
    end

    context 'when an order is in payment' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'payment')
      end

      it 'returns the customer balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(payment_total - 200.0)
      end
    end

    context 'when an order is awaiting_return' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'awaiting_return')
      end

      it 'returns the customer balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(payment_total - 200.0)
      end
    end

    context 'when an order is returned' do
      let(:payment_total) { order_total }
      let(:non_returned_orders_total) { order_total }

      before do
        order = create(:order, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'returned')
        order = create(:order, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
      end

      it 'returns the customer balance' do
        order = outstanding_balance.query.first
        expect(order.balance_value).to eq(payment_total)
      end
    end

    context 'when there are no orders' do
      it 'returns the order balance' do
        orders = outstanding_balance.query
        expect(orders).to be_empty
      end
    end

    it "should return positive amount when payment_total is less than total" do
      order.payment_total = 20.20
      order.total = 30.30
      expect(order.outstanding_balance).to eq 10.10
    end

    it "should return negative amount when payment_total is greater than total" do
      order.total = 8.20
      order.payment_total = 10.20
      expect(order.outstanding_balance).to be_within(0.001).of(-2.00)
    end
  end

  context "#outstanding_balance?" do
    context 'when total is greater than payment_total' do
      before do
        order.total = 10.10
        order.payment_total = 9.50
      end

      it "returns true" do
        expect(order.outstanding_balance?).to eq(true)
      end
    end

    context "when total is less than payment_total" do
      before do
        order.total = 8.25
        order.payment_total = 10.44
      end

      it "returns true" do
        expect(order.outstanding_balance?).to eq(true)
      end
    end

    context "when total equals payment_total" do
      before do
        order.total = 10.10
        order.payment_total = 10.10
      end

      it 'returns false' do
        expect(order.outstanding_balance?).to eq(false)
      end
    end
  end
end
