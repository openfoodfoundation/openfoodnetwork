# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Subscriptions
    describe Form do
      describe "creating a new subscription" do
        let!(:shop) { create(:distributor_enterprise) }
        let!(:customer) { create(:customer, enterprise: shop) }
        let!(:product1) { create(:product, supplier: shop) }
        let!(:product2) { create(:product, supplier: shop) }
        let!(:product3) { create(:product, supplier: shop) }
        let!(:variant1) {
          create(:variant, product: product1, unit_value: '100', price: 12.00)
        }
        let!(:variant2) {
          create(:variant, product: product2, unit_value: '1000', price: 6.00)
        }
        let!(:variant3) {
          create(:variant, product: product2, unit_value: '1000',
                           price: 2.50, on_hand: 1)
        }
        let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
        let!(:order_cycle1) {
          create(:simple_order_cycle, coordinator: shop,
                                      orders_open_at: 9.days.ago,
                                      orders_close_at: 2.days.ago)
        }
        let!(:order_cycle2) {
          create(:simple_order_cycle, coordinator: shop,
                                      orders_open_at: 2.days.ago,
                                      orders_close_at: 5.days.from_now)
        }
        let!(:order_cycle3) {
          create(:simple_order_cycle, coordinator: shop,
                                      orders_open_at: 5.days.from_now,
                                      orders_close_at: 12.days.from_now)
        }
        let!(:order_cycle4) {
          create(:simple_order_cycle, coordinator: shop,
                                      orders_open_at: 12.days.from_now,
                                      orders_close_at: 19.days.from_now)
        }
        let!(:outgoing_exchange1) {
          order_cycle1.exchanges.create(sender: shop,
                                        receiver: shop,
                                        variants: [variant1, variant2, variant3],
                                        enterprise_fees: [enterprise_fee])
        }
        let!(:outgoing_exchange2) {
          order_cycle2.exchanges.create(sender: shop,
                                        receiver: shop,
                                        variants: [variant1, variant2, variant3],
                                        enterprise_fees: [enterprise_fee])
        }
        let!(:outgoing_exchange3) {
          order_cycle3.exchanges.create(sender: shop,
                                        receiver: shop,
                                        variants: [variant1, variant3],
                                        enterprise_fees: [])
        }
        let!(:outgoing_exchange4) {
          order_cycle4.exchanges.create(sender: shop,
                                        receiver: shop,
                                        variants: [variant1, variant2, variant3],
                                        enterprise_fees: [enterprise_fee])
        }
        let!(:schedule) {
          create(:schedule, order_cycles: [order_cycle1, order_cycle2, order_cycle3, order_cycle4])
        }
        let!(:payment_method) { create(:payment_method, distributors: [shop]) }
        let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
        let!(:address) { create(:address) }
        let(:subscription) { Subscription.new }

        let!(:params) {
          {
            shop_id: shop.id,
            customer_id: customer.id,
            schedule_id: schedule.id,
            bill_address_attributes: address.clone.attributes,
            ship_address_attributes: address.clone.attributes,
            payment_method_id: payment_method.id,
            shipping_method_id: shipping_method.id,
            begins_at: 4.days.ago,
            ends_at: 14.days.from_now,
            subscription_line_items_attributes: [
              { variant_id: variant1.id, quantity: 1, price_estimate: 7.0 },
              { variant_id: variant2.id, quantity: 2, price_estimate: 8.0 },
              { variant_id: variant3.id, quantity: 3, price_estimate: 9.0 }
            ]
          }
        }

        let(:form) { OrderManagement::Subscriptions::Form.new(subscription, params) }

        it "creates orders for each order cycle in the schedule" do
          expect(form.save).to be true

          expect(subscription.proxy_orders.count).to be 2
          expect(subscription.subscription_line_items.count).to be 3
          expect(subscription.subscription_line_items[0].price_estimate).to eq 13.75
          expect(subscription.subscription_line_items[1].price_estimate).to eq 7.75
          expect(subscription.subscription_line_items[2].price_estimate).to eq 4.25

          # This order cycle has already closed, so no order is initialized
          proxy_order1 = subscription.proxy_orders.find_by(order_cycle_id: order_cycle1.id)
          expect(proxy_order1).to be nil

          # Currently open order cycle, closing after begins_at and before ends_at
          proxy_order2 = subscription.proxy_orders.find_by(order_cycle_id: order_cycle2.id)
          expect(proxy_order2).to be_a ProxyOrder
          order2 = proxy_order2.initialise_order!
          expect(order2.line_items.count).to eq 3
          expect(order2.line_items.find_by(variant_id: variant3.id).quantity).to be 3
          expect(order2.shipments.count).to eq 1
          expect(order2.shipments.first.shipping_method).to eq shipping_method
          expect(order2.payments.count).to eq 1
          expect(order2.payments.first.payment_method).to eq payment_method
          expect(order2.payments.first.state).to eq 'checkout'
          expect(order2.total).to eq 42
          expect(order2.completed?).to be false

          # Future order cycle, closing after begins_at and before ends_at
          # Adds line items for variants that aren't yet available from the order cycle
          proxy_order3 = subscription.proxy_orders.find_by(order_cycle_id: order_cycle3.id)
          expect(proxy_order3).to be_a ProxyOrder
          order3 = proxy_order3.initialise_order!
          expect(order3).to be_a Spree::Order
          expect(order3.line_items.count).to eq 3
          expect(order2.line_items.find_by(variant_id: variant3.id).quantity).to be 3
          expect(order3.shipments.count).to eq 1
          expect(order3.shipments.first.shipping_method).to eq shipping_method
          expect(order3.payments.count).to eq 1
          expect(order3.payments.first.payment_method).to eq payment_method
          expect(order3.payments.first.state).to eq 'checkout'
          expect(order3.total).to eq 31.50
          expect(order3.completed?).to be false

          # Future order cycle closing after ends_at
          proxy_order4 = subscription.proxy_orders.find_by(order_cycle_id: order_cycle4.id)
          expect(proxy_order4).to be nil
        end
      end
    end
  end
end
