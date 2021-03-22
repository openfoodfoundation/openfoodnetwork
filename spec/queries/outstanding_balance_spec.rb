# frozen_string_literal: true

require 'spec_helper'

describe OutstandingBalance do
  subject(:outstanding_balance) { described_class.new(relation) }

  describe '#statement' do
    let(:relation) { Spree::Order.none }

    it 'returns the CASE statement necessary to compute the order balance' do
      normalized_sql_statement = normalize(outstanding_balance.statement)

      expect(normalized_sql_statement).to eq(normalize(<<-SQL))
        CASE WHEN "spree_orders"."state" IN ('canceled', 'returned') THEN "spree_orders"."payment_total"
             WHEN "spree_orders"."state" IS NOT NULL THEN "spree_orders"."payment_total" - "spree_orders"."total"
        ELSE 0 END
      SQL
    end

    def normalize(sql)
      sql.strip_heredoc.gsub("\n", '').squeeze(' ')
    end
  end

  describe '#query' do
    let(:relation) { Spree::Order.all }
    let(:total) { 200.00 }
    let(:order_total) { 100.00 }

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
  end
end
