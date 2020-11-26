# frozen_string_literal: true

require 'spec_helper'

describe CustomersWithBalance do
  subject(:customers_with_balance) { described_class.new(customer.enterprise.id) }

  describe '#query' do
    let(:customer) { create(:customer) }

    context 'when orders are in cart state' do
      let(:total) { 200.00 }
      let(:order_total) { 100.00 }

      before do
        create(:order, customer: customer, total: order_total, payment_total: 0, state: 'cart')
        create(:order, customer: customer, total: order_total, payment_total: 0, state: 'cart')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(0)
      end
    end

    context 'when no orders where paid' do
      let(:total) { 200.00 }
      let(:order_total) { 100.00 }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'checkout')
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'checkout')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(-total)
      end
    end

    context 'when an order was paid' do
      let(:total) { 200.00 }
      let(:order_total) { 100.00 }
      let(:payment_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'checkout')
        order = create(:order, customer: customer, total: order_total, payment_total: payment_total)
        order.update_attribute(:state, 'checkout')
      end

      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(payment_total - total)
      end
    end

    context 'when an order is canceled' do
      let(:total) { 200.00 }
      let(:order_total) { 100.00 }
      let(:payment_total) { 100.00 }
      let(:non_canceled_orders_total) { order_total }

      before do
        order = create(:order, customer: customer, total: order_total, payment_total: 0)
        order.update_attribute(:state, 'checkout')
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

    context 'when there are no orders' do
      it 'returns the customer balance' do
        customer = customers_with_balance.query.first
        expect(customer.balance_value).to eq(0)
      end
    end
  end
end
