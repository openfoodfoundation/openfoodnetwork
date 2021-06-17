# frozen_string_literal: true

require 'spec_helper'

describe Balance do
  context "#new_outstanding_balance" do
    context 'when orders are in cart state' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'cart') }

      it 'returns the order balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when orders are in address state' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'address') }

      it 'returns the order balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when orders are in delivery state' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'delivery') }

      it 'returns the order balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when orders are in payment state' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'payment') }

      it 'returns the order balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when no orders where paid' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'complete') }

      it 'returns the customer balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when an order was paid' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'complete') }

      it 'returns the customer balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when an order is canceled' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'canceled') }

      it 'returns the customer balance' do
        expect(order.new_outstanding_balance).to eq(-10)
      end
    end

    context 'when an order is resumed' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'resumed') }

      it 'returns the customer balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when an order is in payment' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'payment') }

      it 'returns the customer balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when an order is awaiting_return' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'awaiting_return') }

      it 'returns the customer balance' do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when an order is returned' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'returned') }

      it 'returns the balance' do
        expect(order.new_outstanding_balance).to eq(-10)
      end
    end

    context 'when payment_total is less than total' do
      let(:order) { build(:order, total: 100, payment_total: 10, state: 'complete') }

      it "returns positive" do
        expect(order.new_outstanding_balance).to eq(100 - 10)
      end
    end

    context 'when payment_total is greater than total' do
      let(:order) { create(:order, total: 8.20, payment_total: 10.20, state: 'complete') }

      it "returns negative amount" do
        expect(order.new_outstanding_balance).to eq(-2.00)
      end
    end
  end

  context '#outstanding_balance?' do
    context 'when total is greater than payment_total' do
      let(:order) { build(:order, total: 10.10, payment_total: 9.50) }

      it 'returns true' do
        expect(order.outstanding_balance?).to eq(true)
      end
    end

    context 'when total is less than payment_total' do
      let(:order) { build(:order, total: 8.25, payment_total: 10.44) }

      it 'returns true' do
        expect(order.outstanding_balance?).to eq(true)
      end
    end

    context "when total equals payment_total" do
      let(:order) { build(:order, total: 10.10, payment_total: 10.10) }

      it 'returns false' do
        expect(order.outstanding_balance?).to eq(false)
      end
    end
  end
end
