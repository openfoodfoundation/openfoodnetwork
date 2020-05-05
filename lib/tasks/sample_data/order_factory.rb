# frozen_string_literal: true

require "tasks/sample_data/logging"
require "tasks/sample_data/addressing"

class OrderFactory
  include Logging
  include Addressing

  def create_samples
    log "Creating a sample order"
    order_cycle = OrderCycle.find_by(name: "Fredo's Farm Hub OC")
    distributor = Enterprise.find_by(name: "Fredo's Farm Hub")

    create_order(
      "new.customer@example.org",
      order_cycle,
      distributor
    )
  end

  private

  def create_order(email, order_cycle, distributor)
    order = Spree::Order.create!(
      email: email,
      order_cycle: order_cycle,
      distributor: distributor,
      bill_address: order_address,
      ship_address: order_address
    )
    order.line_items.create( variant_id: variant(order_cycle).id, quantity: 5 )
    order.payments.create(payment_method_id: payment_method_id(distributor))

    place_order(order)
  end

  def variant(order_cycle)
    # First variant on the first outgoing exchange of the OC
    order_cycle.exchanges.outgoing.first.variants.first
  end

  def payment_method_id(distributor)
    # First payment method of the distributor
    distributor.payment_methods.first.id
  end

  def place_order(order)
    order.save

    AdvanceOrderService.new(order).call
    order
  end

  def order_address
    address = address("25 Myrtle Street, Bayswater, 3153")
    address.firstname = "John"
    address.lastname = "Mistery"
    address.phone = "0987654321"
    address
  end
end
