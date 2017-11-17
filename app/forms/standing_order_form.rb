require 'open_food_network/proxy_order_syncer'

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
  delegate :credit_card_id, to: :standing_order

  validates_presence_of :shop, :customer, :schedule, :payment_method, :shipping_method
  validates_presence_of :bill_address, :ship_address, :begins_at
  validate :ends_at_after_begins_at?
  validate :customer_allowed?
  validate :schedule_allowed?
  validate :payment_method_allowed?
  validate :shipping_method_allowed?
  validate :standing_line_items_present?
  validate :standing_line_items_available?
  validate :credit_card_ok?

  def initialize(standing_order, params = {}, fee_calculator = nil)
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
      proxy_order_syncer.sync!
      update_initialised_orders
      standing_order.save!
    end
  end

  def json_errors
    errors.messages.each_with_object({}) do |(k, v), errors|
      errors[k] = v.map { |msg| build_msg_from(k, msg) }
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

  def proxy_order_syncer
    OpenFoodNetwork::ProxyOrderSyncer.new(standing_order)
  end

  def changed_standing_line_items
    standing_line_items.select{ |sli| sli.changed? && sli.persisted? }
  end

  def new_standing_line_items
    standing_line_items.select(&:new_record?)
  end

  def validate_price_estimates
    item_attributes = params[:standing_line_items_attributes]
    return if item_attributes.blank?
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
    ["firstname", "lastname", "address1", "zipcode", "city", "state_id", "country_id", "phone"]
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
    return if standing_order.valid?
    standing_order.errors.each do |k, msg|
      errors.add(k, msg)
    end
  end

  def ends_at_after_begins_at?
    # Does not add error even if ends_at is nil
    # Note: presence of begins_at validated on the model
    return if begins_at.blank? || ends_at.blank?
    return if ends_at > begins_at
    errors.add(:ends_at, "must be after begins at")
  end

  def customer_allowed?
    return unless customer
    return if customer.enterprise == shop
    errors[:customer] << "does not belong to #{shop.name}"
  end

  def schedule_allowed?
    return unless schedule
    return if schedule.coordinators.include?(shop)
    errors[:schedule] << "is not coordinated by #{shop.name}"
  end

  def payment_method_allowed?
    return unless payment_method

    if payment_method.distributors.exclude?(shop)
      errors[:payment_method] << "is not available to #{shop.name}"
    end

    return if StandingOrder::ALLOWED_PAYMENT_METHOD_TYPES.include? payment_method.type
    errors[:payment_method] << "must be a Cash or Stripe method"
  end

  def shipping_method_allowed?
    return unless shipping_method
    return if shipping_method.distributors.include?(shop)
    errors[:shipping_method] << "is not available to #{shop.name}"
  end

  def standing_line_items_present?
    return if standing_line_items.reject(&:marked_for_destruction?).any?
    errors.add(:standing_line_items, :at_least_one_product)
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

  def credit_card_ok?
    return unless payment_method.andand.type == "Spree::Gateway::StripeConnect"
    return errors[:credit_card] << "is required" unless credit_card_id
    return if customer.andand.user.andand.credit_card_ids.andand.include? credit_card_id
    errors[:credit_card] << "is not available"
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
    errors.full_message(k, msg)
  end
end
