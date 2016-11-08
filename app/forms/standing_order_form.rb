class StandingOrderForm
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :standing_order, :params

  delegate :orders, :order_cycles, :bill_address, :ship_address, :standing_line_items, to: :standing_order
  delegate :shop, :shop_id, :customer, :customer_id, to: :standing_order
  delegate :shipping_method, :shipping_method_id, :payment_method, :payment_method_id, to: :standing_order
  delegate :shipping_method_id_changed?, :shipping_method_id_was, :payment_method_id_changed?, :payment_method_id_was, to: :standing_order

  def initialize(standing_order, params)
    @standing_order = standing_order
    @params = params
  end

  def save
    @standing_order.transaction do
      @standing_order.assign_attributes(params)

      initialise_orders!

      orders.update_all(customer_id: customer_id, email: customer.andand.email, distributor_id: shop_id)

      orders.each do |order|
        update_shipment_for(order) if shipping_method_id_changed?
        update_payment_for(order) if payment_method_id_changed?
      end

      standing_order.save
    end
  end

  def json_errors
    @standing_order.errors.messages.inject({}) do |errors, (k,v)|
      errors[k] = v.map{ |msg| @standing_order.errors.full_message(k,msg) }
      errors
    end
  end

  private

  def future_and_undated_orders
    orders.joins(:order_cycle).merge(OrderCycle.not_closed)
  end

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

  def update_payment_for(order)
    payment = order.payments.with_state('checkout').where(payment_method_id: payment_method_id_was).last
    if payment
      payment.andand.void_transaction!
      create_payment_for(order)
    end
  end

  def update_shipment_for(order)
    shipment = order.shipments.with_state('pending').where(shipping_method_id: shipping_method_id_was).last
    if shipment
      shipment.update_attributes(shipping_method_id: shipping_method_id)
      order.update_attribute(:shipping_method_id, shipping_method_id)
    end
  end

  def initialise_orders!
    uninitialised_order_cycle_ids.each do |order_cycle_id|
      orders << create_order_for(order_cycle_id)
    end
  end

  def uninitialised_order_cycle_ids
    order_cycles.pluck(:id) - orders.map(&:order_cycle_id)
  end
end
