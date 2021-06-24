# frozen_string_literal: true

require 'spec_helper'

describe CompleteOrdersWithBalance do
  let(:complete_orders_with_balance) { described_class.new(user) }

  describe '#query' do
    let(:user) { order.user }
    let(:outstanding_balance) { instance_double(OutstandingBalance) }

    context 'when the user has complete orders' do
      let(:order) do
        create(:order, state: 'complete', total: 2.0, payment_total: 1.0, completed_at: 2.days.ago)
      end
      let!(:other_order) do
        create(
          :order,
          user: user,
          state: 'complete',
          total: 2.0,
          payment_total: 1.0,
          completed_at: 1.day.ago
        )
      end

      it 'calls OutstandingBalance#query' do
        allow(OutstandingBalance).to receive(:new).and_return(outstanding_balance)
        expect(outstanding_balance).to receive(:query)

        complete_orders_with_balance.query
      end

      it 'returns complete orders including their balance' do
        order = complete_orders_with_balance.query.first
        expect(order[:balance_value]).to eq(-1.0)
      end

      it 'sorts them by their completed_at with the most recent first' do
        orders = complete_orders_with_balance.query
        expect(orders.pluck(:id)).to eq([other_order.id, order.id])
      end
    end

    context 'when the user has no complete orders' do
      let(:order) { create(:order) }

      it 'calls OutstandingBalance' do
        allow(OutstandingBalance).to receive(:new).and_return(outstanding_balance)
        expect(outstanding_balance).to receive(:query)

        complete_orders_with_balance.query
      end

      it 'returns an empty array' do
        order = complete_orders_with_balance.query
        expect(order).to be_empty
      end
    end
  end
end
