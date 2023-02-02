# frozen_string_literal: true

module ReportsHelper
  def report_order_cycle_options(order_cycles)
    order_cycles.map do |oc|
      orders_open_at = oc.orders_open_at&.to_fs(:short) || 'NA'
      orders_close_at = oc.orders_close_at&.to_fs(:short) || 'NA'
      ["#{oc.name} &nbsp; (#{orders_open_at} - #{orders_close_at})".html_safe, oc.id]
    end
  end

  def report_payment_method_options(orders)
    orders.map do |order|
      payment_method = order.payments.last&.payment_method

      next unless payment_method

      [payment_method.name, payment_method.id]
    end.compact.uniq
  end

  def report_shipping_method_options(orders)
    orders.map do |o|
      sm = o.shipping_method
      [sm&.name, sm&.id]
    end.uniq
  end

  def customer_email_options(order_customers)
    order_customers.map do |customer|
      [customer&.email, customer&.id]
    end
  end

  def fee_name_options(orders)
    EnterpriseFee.where(id: enterprise_fee_ids(orders))
      .pluck(:name, :id)
  end

  def fee_owner_options(orders)
    Enterprise.where(id: enterprise_fee_owner_ids(orders))
      .pluck(:name, :id)
  end

  def currency_symbol
    Spree::Money.currency_symbol
  end

  def enterprise_fee_owner_ids(orders)
    EnterpriseFee.where(id: enterprise_fee_ids(orders))
      .pluck(:enterprise_id)
  end

  def enterprise_fee_ids(orders)
    Spree::Adjustment.enterprise_fee
      .where(order_id: orders.map(&:id))
      .pluck(:originator_id)
  end
end
