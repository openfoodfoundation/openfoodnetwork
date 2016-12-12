class StandingOrderForm
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :standing_order, :params, :fee_calculator

  delegate :orders, :order_cycles, :bill_address, :ship_address, :standing_line_items, to: :standing_order
  delegate :shop, :shop_id, :customer, :customer_id, :begins_at, :ends_at, :proxy_orders, to: :standing_order
  delegate :shipping_method, :shipping_method_id, :payment_method, :payment_method_id, to: :standing_order
  delegate :shipping_method_id_changed?, :shipping_method_id_was, :payment_method_id_changed?, :payment_method_id_was, to: :standing_order

  def initialize(standing_order, params={}, fee_calculator=nil)
    @standing_order = standing_order
    @params = params
    @fee_calculator = fee_calculator
  end

  def save
    standing_order.transaction do
      validate_price_estimates
      standing_order.assign_attributes(params)

      initialise_proxy_orders!
      remove_obsolete_proxy_orders!

      orders.update_all(customer_id: customer_id, email: customer.andand.email, distributor_id: shop_id)

      orders.each do |order|
        update_shipment_for(order) if shipping_method_id_changed?
        update_payment_for(order) if payment_method_id_changed?
      end

      changed_standing_line_items.each do |sli|
        updateable_line_items(sli).each{ |li| li.update_attributes(quantity: sli.quantity, skip_stock_check: true)}
      end

      new_standing_line_items.each do |sli|
        future_and_undated_orders.each do |order|
          order.line_items.create(variant_id: sli.variant_id, quantity: sli.quantity, skip_stock_check: true)
        end
      end

      standing_line_items.select(&:marked_for_destruction?).each do |sli|
        updateable_line_items(sli).destroy_all
      end

      future_and_undated_orders.each(&:save)

      raise ActiveRecord::Rollback unless standing_order.save
      true
    end
  end

  def json_errors
    standing_order.errors.messages.inject({}) do |errors, (k,v)|
      errors[k] = v.map{ |msg| standing_order.errors.full_message(k,msg) }
      errors
    end
  end

  private

  def future_and_undated_orders
    return @future_and_undated_orders unless @future_and_undated_orders.nil?
    @future_and_undated_orders = orders.joins(:order_cycle).merge(OrderCycle.not_closed).readonly(false)
  end

  def update_payment_for(order)
    payment = order.payments.with_state('checkout').where(payment_method_id: payment_method_id_was).last
    if payment
      payment.andand.void_transaction!
      order.payments.create(payment_method_id: payment_method_id, amount: order.reload.total)
    end
  end

  def update_shipment_for(order)
    shipment = order.shipments.with_state('pending').where(shipping_method_id: shipping_method_id_was).last
    if shipment
      shipment.update_attributes(shipping_method_id: shipping_method_id)
      order.update_attribute(:shipping_method_id, shipping_method_id)
    end
  end

  def initialise_proxy_orders!
    uninitialised_order_cycle_ids.each do |order_cycle_id|
      proxy_orders << ProxyOrder.new(standing_order: standing_order, order_cycle_id: order_cycle_id)
    end
  end

  def uninitialised_order_cycle_ids
    not_closed_in_range_order_cycles.pluck(:id) - proxy_orders.map(&:order_cycle_id)
  end

  def remove_obsolete_proxy_orders!
    obsolete_proxy_orders.destroy_all
  end

  def obsolete_proxy_orders
    in_range_order_cycle_ids = in_range_order_cycles.pluck(:id)
    return proxy_orders unless in_range_order_cycle_ids.any?
    proxy_orders.where('order_cycle_id NOT IN (?)', in_range_order_cycle_ids)
  end

  def not_closed_in_range_order_cycles
    in_range_order_cycles.merge(OrderCycle.not_closed)
  end

  def in_range_order_cycles
    order_cycles.where('orders_close_at >= ? AND orders_close_at <= ?', begins_at, ends_at || 100.years.from_now)
  end

  def changed_standing_line_items
    standing_line_items.select{ |sli| sli.changed? && sli.persisted? }
  end

  def new_standing_line_items
    standing_line_items.select(&:new_record?)
  end

  def updateable_line_items(sli)
    line_items_from_future_and_undated_orders(sli.variant_id).where(quantity: sli.quantity_was)
  end

  def line_items_from_future_and_undated_orders(variant_id)
    Spree::LineItem.where(order_id: future_and_undated_orders, variant_id: variant_id)
  end

  def validate_price_estimates
    item_attributes = params[:standing_line_items_attributes]
    return unless item_attributes.present?
    if fee_calculator
      item_attributes.each do |item_attrs|
        if variant = Spree::Variant.find_by_id(item_attrs[:variant_id])
          item_attrs[:price_estimate] = price_estimate_for(variant)
        else
          item_attrs.delete(:price_estimate)
        end
      end
    else
      item_attributes.each { |item_attrs| item_attrs.delete(:price_estimate) }
    end
  end

  def price_estimate_for(variant)
    fees = fee_calculator.indexed_fees_for(variant)
    (variant.price + fees).to_d
  end
end
