# Responsible for ensuring that any updates to a Standing Order are propagated to any
# orders belonging to that Standing Order which have been instantiated

class OrderSyncer
  attr_reader :order_update_issues

  def initialize(standing_order)
    @standing_order = standing_order
    @order_update_issues = OrderUpdateIssues.new
    @line_item_syncer = LineItemSyncer.new(standing_order, order_update_issues)
  end

  def sync!
    future_and_undated_orders.all? do |order|
      order.assign_attributes(customer_id: customer_id, email: customer.andand.email, distributor_id: shop_id)
      update_associations_for(order)
      line_item_syncer.sync!(order)
      order.save
    end
  end

  private

  attr_reader :standing_order, :line_item_syncer

  delegate :orders, :bill_address, :ship_address, :standing_line_items, to: :standing_order
  delegate :shop_id, :customer, :customer_id, to: :standing_order
  delegate :shipping_method, :shipping_method_id, :payment_method, :payment_method_id, to: :standing_order
  delegate :shipping_method_id_changed?, :shipping_method_id_was, to: :standing_order
  delegate :payment_method_id_changed?, :payment_method_id_was, to: :standing_order

  def update_associations_for(order)
    update_bill_address_for(order) if (bill_address.changes.keys & relevant_address_attrs).any?
    update_ship_address_for(order) if (ship_address.changes.keys & relevant_address_attrs).any?
    update_shipment_for(order) if shipping_method_id_changed?
    update_payment_for(order) if payment_method_id_changed?
  end

  def future_and_undated_orders
    return @future_and_undated_orders unless @future_and_undated_orders.nil?
    @future_and_undated_orders = orders.joins(:order_cycle).merge(OrderCycle.not_closed).readonly(false)
  end

  def update_bill_address_for(order)
    unless addresses_match?(order.bill_address, bill_address)
      return order_update_issues.add(order, I18n.t('bill_address'))
    end
    order.bill_address.update_attributes(bill_address.attributes.slice(*relevant_address_attrs))
  end

  def update_ship_address_for(order)
    force_update = force_ship_address_update_for?(order)
    return unless force_update || order.shipping_method.require_ship_address?
    unless force_update || addresses_match?(order.ship_address, ship_address)
      return order_update_issues.add(order, I18n.t('ship_address'))
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
        order_update_issues.add(order, I18n.t('admin.payment_method'))
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
        order_update_issues.add(order, I18n.t('admin.shipping_method'))
      end
    end
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
end
