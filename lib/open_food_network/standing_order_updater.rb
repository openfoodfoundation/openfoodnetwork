module OpenFoodNetwork
  module StandingOrderUpdater

    def update_orders!
      uninitialised_order_cycle_ids.each do |order_cycle_id|
        orders << create_order_for(order_cycle_id)
      end

      orders.update_all(customer_id: customer_id, email: customer.email, distributor_id: shop_id, shipping_method_id: shipping_method_id)

      orders.each do |order|
        if shipping_method_id_changed?
          shipment = order.shipments.with_state('pending').where(shipping_method_id: shipping_method_id_was).last
          shipment.andand.update_attributes(shipping_method_id: shipping_method_id)
        end
        if payment_method_id_changed?
          payment = order.payments.with_state('checkout').where(payment_method_id: payment_method_id_was).last
          if payment
            payment.andand.void_transaction!
            create_payment_for(order)
          end
        end
      end
    end

    private

    def create_order_for(order_cycle_id)
      order = Spree::Order.create!({
        customer_id: customer_id,
        email: customer.email,
        order_cycle_id: order_cycle_id,
        distributor_id: shop_id,
        shipping_method_id: shipping_method_id,
      })
      standing_line_items.each do |sli|
        order.line_items.create(variant_id: sli.variant_id, quantity: sli.quantity)
      end
      order.update_attributes(bill_address: bill_address.dup, ship_address: ship_address.dup)
      order.update_distribution_charge!
      create_payment_for(order)

      order
    end

    def create_payment_for(order)
      order.payments.create(payment_method_id: payment_method_id, amount: order.reload.total)
    end

    def uninitialised_order_cycle_ids
      order_cycles.pluck(:id) - orders.map(&:order_cycle_id)
    end
  end
end
