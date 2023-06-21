# frozen_string_literal: true

# Responsible for ensuring that any updates to a Subscription are propagated to any
# orders belonging to that Subscription which have been instantiated
class OrderSyncer
  attr_reader :order_update_issues

  def initialize(subscription)
    @subscription = subscription
    @order_update_issues = OrderUpdateIssues.new
    @line_item_syncer = LineItemSyncer.new(subscription, order_update_issues)
  end

  def sync!
    orders_in_order_cycles_not_closed.all? do |order|
      order.assign_attributes(customer_id: customer_id, email: customer&.email,
                              distributor_id: shop_id)
      update_associations_for(order)
      line_item_syncer.sync!(order)
      order.update_order!
      order.save
    end
  end

  private

  attr_reader :subscription, :line_item_syncer

  delegate :orders, :bill_address, :ship_address, :subscription_line_items, to: :subscription
  delegate :shop_id, :customer, :customer_id, to: :subscription
  delegate :shipping_method, :shipping_method_id,
           :payment_method, :payment_method_id, to: :subscription
  delegate :shipping_method_id_changed?, :shipping_method_id_was, to: :subscription
  delegate :payment_method_id_changed?, :payment_method_id_was, to: :subscription

  def update_associations_for(order)
    update_bill_address_for(order) if (bill_address.changes.keys & relevant_address_attrs).any?
    update_shipment_for(order) if shipping_method_id_changed?
    update_ship_address_for(order)
    update_payment_for(order) if payment_method_id_changed?
  end

  def orders_in_order_cycles_not_closed
    return @orders_in_order_cycles_not_closed unless @orders_in_order_cycles_not_closed.nil?

    @orders_in_order_cycles_not_closed = orders.joins(:order_cycle).
      merge(OrderCycle.not_closed).readonly(false)
  end

  def update_bill_address_for(order)
    unless addresses_match?(order.bill_address, bill_address)
      return order_update_issues.add(order, I18n.t('bill_address'))
    end

    order.bill_address.update(bill_address.attributes.slice(*relevant_address_attrs))
  end

  def update_payment_for(order)
    payment = order.payments.
      with_state('checkout').where(payment_method_id: payment_method_id_was).last
    if payment
      payment&.void_transaction!
      order.payments.create(payment_method_id: payment_method_id, amount: order.reload.total)
    else
      unless order.payments.with_state('checkout').where(payment_method_id: payment_method_id).any?
        order_update_issues.add(order, I18n.t('admin.payment_method'))
      end
    end
  end

  def update_shipment_for(order)
    return if pending_shipment_with?(order, shipping_method_id) # No need to do anything.

    if pending_shipment_with?(order, shipping_method_id_was)
      order.select_shipping_method(shipping_method_id)
    else
      order_update_issues.add(order, I18n.t('admin.shipping_method'))
    end
  end

  def update_ship_address_for(order)
    # The conditions here are to achieve the same behaviour in earlier versions of Spree, where
    # switching from pick-up to delivery affects whether simultaneous changes to shipping address
    # are ignored or not.
    pickup_to_delivery = force_ship_address_required?(order)
    if (!pickup_to_delivery || order.shipment.present?) &&
       (ship_address.changes.keys & relevant_address_attrs).any?
      save_ship_address_in_order(order)
    end
    if !pickup_to_delivery || order.shipment.blank?
      order.updater.shipping_address_from_distributor
    end
  end

  def relevant_address_attrs
    ["firstname", "lastname", "address1", "zipcode", "city", "state_id", "country_id", "phone"]
  end

  def addresses_match?(order_address, subscription_address)
    relevant_address_attrs.all? do |attr|
      order_address[attr] == subscription_address.public_send("#{attr}_was") ||
        order_address[attr] == subscription_address[attr]
    end
  end

  def ship_address_updatable?(order)
    return true if force_ship_address_required?(order)
    return false unless order.shipping_method.require_ship_address?
    return true if addresses_match?(order.ship_address, ship_address)

    order_update_issues.add(order, I18n.t('ship_address'))
    false
  end

  # This returns true when the shipping method on the subscription has changed
  # to a delivery (ie. a shipping address is required) AND the existing shipping
  # address on the order matches the shop's address
  def force_ship_address_required?(order)
    return false unless shipping_method.require_ship_address?

    distributor_address = order.address_from_distributor
    relevant_address_attrs.all? do |attr|
      order.ship_address[attr] == distributor_address[attr]
    end
  end

  def save_ship_address_in_order(order)
    return unless ship_address_updatable?(order)

    order.ship_address.update(ship_address.attributes.slice(*relevant_address_attrs))
  end

  def pending_shipment_with?(order, shipping_method_id)
    return false unless order.shipment.present? && order.shipment.state == "pending"

    order.shipping_method.id == shipping_method_id
  end
end
