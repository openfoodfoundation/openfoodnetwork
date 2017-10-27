class StandingOrderForm
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :standing_order, :params, :fee_calculator, :order_update_issues

  delegate :orders, :order_cycles, :bill_address, :ship_address, :standing_line_items, to: :standing_order
  delegate :shop, :shop_id, :customer, :customer_id, :begins_at, :ends_at, :proxy_orders, to: :standing_order
  delegate :schedule, :schedule_id, to: :standing_order
  delegate :shipping_method, :shipping_method_id, :payment_method, :payment_method_id, to: :standing_order
  delegate :shipping_method_id_changed?, :shipping_method_id_was, :payment_method_id_changed?, :payment_method_id_was, to: :standing_order

  validates_presence_of :shop, :customer, :schedule, :payment_method, :shipping_method
  validates_presence_of :bill_address, :ship_address, :begins_at
  validate :ends_at_after_begins_at?
  validate :customer_allowed?
  validate :schedule_allowed?
  validate :payment_method_allowed?
  validate :shipping_method_allowed?
  validate :standing_line_items_present?
  validate :standing_line_items_available?

  def initialize(standing_order, params={}, fee_calculator=nil)
    @standing_order = standing_order
    @params = params
    @fee_calculator = fee_calculator
    @order_update_issues = {}
  end

  def save
    validate_price_estimates
    standing_order.assign_attributes(params)
    return false unless valid?
    standing_order.transaction do
      initialise_proxy_orders!
      remove_obsolete_proxy_orders!
      update_initialised_orders
      standing_order.save!
    end
  end

  def json_errors
    errors.messages.inject({}) do |errors, (k,v)|
      errors[k] = v.map { |msg| build_msg_from(k, msg) }
      errors
    end
  end

  private

  def update_initialised_orders
    future_and_undated_orders.each do |order|
      order.assign_attributes(customer_id: customer_id, email: customer.andand.email, distributor_id: shop_id)

      update_bill_address_for(order) if (bill_address.changes.keys & relevant_address_attrs).any?
      update_ship_address_for(order) if (ship_address.changes.keys & relevant_address_attrs).any?
      update_shipment_for(order) if shipping_method_id_changed?
      update_payment_for(order) if payment_method_id_changed?

      changed_standing_line_items.each do |sli|
        line_item = order.line_items.find_by_variant_id(sli.variant_id)
        if line_item.quantity == sli.quantity_was
          line_item.update_attributes(quantity: sli.quantity, skip_stock_check: true)
        else
          unless line_item.quantity == sli.quantity
            product_name = "#{line_item.product.name} - #{line_item.full_name}"
            add_order_update_issue(order, product_name)
          end
        end
      end

      new_standing_line_items.each do |sli|
        order.line_items.create(variant_id: sli.variant_id, quantity: sli.quantity, skip_stock_check: true)
      end

      order.line_items.where(variant_id: standing_line_items.select(&:marked_for_destruction?).map(&:variant_id)).destroy_all

      order.save
    end
  end

  def future_and_undated_orders
    return @future_and_undated_orders unless @future_and_undated_orders.nil?
    @future_and_undated_orders = orders.joins(:order_cycle).merge(OrderCycle.not_closed).readonly(false)
  end

  def update_bill_address_for(order)
    unless addresses_match?(order.bill_address, bill_address)
      return add_order_update_issue(order, I18n.t('bill_address'))
    end
    order.bill_address.update_attributes(bill_address.attributes.slice(*relevant_address_attrs))
  end

  def update_ship_address_for(order)
    force_update = force_ship_address_update_for?(order)
    return unless force_update || order.shipping_method.require_ship_address?
    unless force_update || addresses_match?(order.ship_address, ship_address)
      return add_order_update_issue(order, I18n.t('ship_address'))
    end
    order.ship_address.update_attributes(ship_address.attributes.slice(*relevant_address_attrs))
  end

  def update_payment_for(order)
    payment = order.payments.with_state('checkout').where(payment_method_id: payment_method_id_was).last
    if payment
      payment.andand.void_transaction!
      order.payments.create(payment_method_id: payment_method_id, amount: order.reload.total)
    else
      unless order.payments.with_state('checkout').where(payment_method_id: payment_method_id).any?
        add_order_update_issue(order, I18n.t('admin.payment_method'))
      end
    end
  end

  def update_shipment_for(order)
    shipment = order.shipments.with_state('pending').where(shipping_method_id: shipping_method_id_was).last
    if shipment
      shipment.update_attributes(shipping_method_id: shipping_method_id)
      order.update_attribute(:shipping_method_id, shipping_method_id)
    else
      unless order.shipments.with_state('pending').where(shipping_method_id: shipping_method_id).any?
        add_order_update_issue(order, I18n.t('admin.shipping_method'))
      end
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

  def add_order_update_issue(order, issue)
    order_update_issues[order.id] ||= []
    order_update_issues[order.id] << issue
  end

  def relevant_address_attrs
    ["firstname","lastname","address1","zipcode","city","state_id","country_id","phone"]
  end

  def addresses_match?(order_address, standing_order_address)
    relevant_address_attrs.all? do |attr|
      order_address[attr] == standing_order_address.send("#{attr}_was") ||
      order_address[attr] == standing_order_address[attr]
    end
  end

  def force_ship_address_update_for?(order)
    return false unless shipping_method.require_ship_address?
    distributor_address = order.send(:address_from_distributor)
    relevant_address_attrs.all? do |attr|
      order.ship_address[attr] == distributor_address[attr]
    end
  end

  def standing_order_valid?
    unless standing_order.valid?
      standing_order.errors.each do |k, msg|
        errors.add(k, msg)
      end
    end
  end

  def ends_at_after_begins_at?
    # Returns true even if ends_at is false
    # Note: presence of begins_at validated on the model
    if begins_at.present? && ends_at.present? && ends_at <= begins_at
      errors.add(:ends_at, "must be after begins at")
    end
  end

  def customer_allowed?
    if customer && customer.enterprise != shop
      errors[:customer] << "does not belong to #{shop.name}"
    end
  end

  def schedule_allowed?
    if schedule && schedule.coordinators.exclude?(shop)
      errors[:schedule] << "is not coordinated by #{shop.name}"
    end
  end

  def payment_method_allowed?
    return unless payment_method

    if payment_method.distributors.exclude?(shop)
      errors[:payment_method] << "is not available to #{shop.name}"
    end

    if StandingOrder::ALLOWED_PAYMENT_METHOD_TYPES.exclude? payment_method.type
      errors[:payment_method] << "must be a Cash or Stripe method"
    end
  end

  def shipping_method_allowed?
    if shipping_method && shipping_method.distributors.exclude?(shop)
      errors[:shipping_method] << "is not available to #{shop.name}"
    end
  end

  def standing_line_items_present?
    unless standing_line_items.reject(&:marked_for_destruction?).any?
      errors.add(:standing_line_items, :at_least_one_product)
    end
  end

  def standing_line_items_available?
    available_variant_ids = variant_ids_for_shop_and_schedule
    standing_line_items.each do |sli|
      unless available_variant_ids.include? sli.variant_id
        name = "#{sli.variant.product.name} - #{sli.variant.full_name}"
        errors.add(:standing_line_items, :not_available, name: name)
      end
    end
  end

  def variant_ids_for_shop_and_schedule
    Spree::Variant.joins(exchanges: { order_cycle: :schedules})
    .where(id: standing_line_items.map(&:variant_id))
    .where(schedules: { id: schedule}, exchanges: { incoming: false, receiver_id: shop })
    .merge(OrderCycle.not_closed)
    .select('DISTINCT spree_variants.id')
    .pluck(:id)
  end

  def build_msg_from(k, msg)
    return msg[1..-1] if msg.starts_with?("^")
    errors.full_message(k,msg)
  end
end
