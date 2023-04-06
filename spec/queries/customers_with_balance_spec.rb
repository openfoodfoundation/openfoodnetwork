# frozen_string_literal: true

require 'spec_helper'

describe CustomersWithBalance do
  subject(:customers_with_balance) { described_class.new(Customer.where(id: customer)) }

  describe '#query' do
    let(:customer) { create(:customer) }
    let(:total) { 200.00 }
    let(:order_total) { 100.00 }
    let(:outstanding_balance) { instance_double(OutstandingBalance) }

    it 'calls CustomersWithBalance#statement' do
      allow(OutstandingBalance).to receive(:new).and_return(outstanding_balance)
      expect(outstanding_balance).to receive(:statement)

      customers_with_balance.query
    end

    describe 'arguments' do
      context 'with customers collection' do
        it 'returns balance' do
          customers = create_pair(:customer)
          query = described_class.new(Customer.where(id: customers)).query
          expect(query.pluck(:id).sort).to eq([customers.first.id, customers.second.id].sort)
          expect(query.map(&:balance_value)).to eq([0, 0])
        end
      end

      context 'with empty customers collection' do
        it 'returns empty customers collection' do
          expect(described_class.new(Customer.none).query).to eq([])
        end
      end
    end

    context 'when orders are in cart state' do
      before do
        create(:order, customer: customer, total: order_total, payment_total: 0, state: 'cart')
        create(:order, customer: customer, total: order_total, payment_total: 0, state: 'cart')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(0)
      end
    end

    context 'when orders are in address state' do
      before do
        create(:order, customer: customer, total: order_total, payment_total: 0, state: 'address')
        create(:order, customer: customer, total: order_total, payment_total: 50, state: 'address')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(0)
      end
    end

    context 'when orders are in delivery state' do
      before do
        create(:order, customer: customer, total: order_total, payment_total: 0, state: 'delivery')
        create(:order, customer: customer, total: order_total, payment_total: 50, state: 'delivery')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(0)
      end
    end

    context 'when orders are in payment state' do
      before do
        create(:order, customer: customer, total: order_total, payment_total: 0, state: 'payment')
        create(:order, customer: customer, total: order_total, payment_total: 50, state: 'payment')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(0)
      end
    end

    context 'when no orders where paid' do
      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(-total)
      end
    end

    context 'when an order was paid' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, customer: customer, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'complete')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(payment_total - total)
      end
    end

    context 'when an order is canceled' do
      let(:payment_total) { 100.00 }
      let(:non_canceled_orders_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        create(
          :order,
          customer: customer,
          total: order_total,
          payment_total: order_total,
          state: 'canceled'
        )
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(payment_total - non_canceled_orders_total)
      end
    end

    context 'when an order is resumed' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, customer: customer, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'resumed')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(payment_total - total)
      end
    end

    context 'when an order is in payment' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, customer: customer, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'payment')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(payment_total - total)
      end
    end

    context 'when an order is awaiting_return' do
      let(:payment_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, customer: customer, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'awaiting_return')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(payment_total - total)
      end
    end

    context 'when an order is returned' do
      let(:payment_total) { order_total }
      let(:non_returned_orders_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'complete')
        order = create(:order, customer: customer, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'returned')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(payment_total - non_returned_orders_total)
      end
    end

    context 'when there are no orders' do
      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(0)
      end
    end
  end
end
