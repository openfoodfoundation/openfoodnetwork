# frozen_string_literal: true

# Creates an order cycle for the provided enterprise and selecting all the
# variants specified for both incoming and outgoing exchanges
class CreateOrderCycle
  # Constructor
  #
  # @param enterprise [Enterprise]
  # @param variants [Array<Spree::Variant>]
  def initialize(enterprise, variants)
    @enterprise = enterprise
    @variants = variants
  end

  # Creates the order cycle
  def call
    incoming_exchange.order_cycle = order_cycle
    incoming_exchange.variants << variants

    outgoing_exchange.order_cycle = order_cycle
    outgoing_exchange.variants << variants

    order_cycle.exchanges << incoming_exchange
    order_cycle.exchanges << outgoing_exchange

    order_cycle.save!
  end

  private

  attr_reader :enterprise, :variants

  # Builds an order cycle for the next month, starting now
  #
  # @return [OrderCycle]
  def order_cycle
    @order_cycle ||= OrderCycle.new(
      coordinator_id: enterprise.id,
      name: 'Monthly order cycle',
      orders_open_at: Time.zone.now,
      orders_close_at: 1.month.from_now
    )
  end

  # Builds an exchange with the enterprise both as sender and receiver
  #
  # @return [Exchange]
  def incoming_exchange
    @incoming_exchange ||= Exchange.new(
      sender_id: enterprise.id,
      receiver_id: enterprise.id,
      incoming: true
    )
  end

  # Builds an exchange with the enterprise both as sender and receiver
  #
  # @return [Exchange]
  def outgoing_exchange
    @outgoing_exchange ||= Exchange.new(
      sender_id: enterprise.id,
      receiver_id: enterprise.id,
      pickup_time: '8 am',
      incoming: false
    )
  end
end
