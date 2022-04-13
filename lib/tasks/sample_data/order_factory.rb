# frozen_string_literal: true

require "tasks/sample_data/logging"
require "tasks/sample_data/addressing"

module SampleData
  class OrderFactory
    include Logging
    include Addressing

    def create_samples
      log "Creating orders"
      @order_cycle = OrderCycle.find_by(name: "Fredo's Farm Hub OC")
      @distributor = Enterprise.find_by(name: "Fredo's Farm Hub")
      @email = "new.customer@example.org"

      log "- cart order"
      create_cart_order

      log "- complete order - not paid"
      create_complete_order

      log "- complete order - paid"
      order = create_complete_order
      order.payments.first.capture!

      log "- complete order - delivery"
      order = create_complete_order
      order.select_shipping_method(delivery_shipping_method_id)
      order.save

      log "- complete order - shipped"
      create_shipped_order
    end

    private

    def create_shipped_order
      order = create_complete_order
      order.payments.first.amount = order.total
      order.payments.first.capture!
      order.save
      order.shipment.reload.ship!
    end

    def create_cart_order
      order = create_order
      order.save
      order
    end

    def create_complete_order
      order = create_cart_order
      OrderWorkflow.new(order).complete
      order
    end

    def create_order
      order = Spree::Order.create!(
        email: @email,
        order_cycle: @order_cycle,
        distributor: @distributor,
        bill_address: order_address,
        ship_address: order_address
      )
      order.line_items.create(variant_id: first_variant.id, quantity: 5)
      order.payments.create(payment_method_id: first_payment_method_id)
      order
    end

    def first_variant
      # First variant on the first outgoing exchange of the OC
      @order_cycle.exchanges.outgoing.first.variants.first
    end

    def first_payment_method_id
      # First payment method of the distributor
      @distributor.payment_methods.first.id
    end

    def delivery_shipping_method_id
      @distributor.shipping_methods.find_by(name: "Home delivery Fredo's Farm Hub").id
    end

    def order_address
      address = address("25 Myrtle Street, Bayswater, 3153")
      address.firstname = "John"
      address.lastname = "Mistery"
      address.phone = "0987654321"
      address
    end
  end
end
