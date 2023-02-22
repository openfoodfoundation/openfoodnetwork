# frozen_string_literal: true

class OrderFeesHandler
  attr_reader :order

  delegate :distributor, :order_cycle, to: :order

  def initialize(order)
    @order = order
  end

  def recreate_all_fees!
    # `with_lock` acquires an exclusive row lock on order so no other
    # requests can update it until the transaction is commited.
    # See https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/locking/pessimistic.rb#L69
    # and https://www.postgresql.org/docs/current/static/sql-select.html#SQL-FOR-UPDATE-SHARE
    order.with_lock do
      EnterpriseFee.clear_all_adjustments order

      create_line_item_fees!
      create_order_fees!
    end

    tax_enterprise_fees!
    order.update_order!
  end

  def create_line_item_fees!
    order.line_items.includes(variant: :product).each do |line_item|
      if provided_by_order_cycle? line_item
        calculator.create_line_item_adjustments_for line_item
      end
    end
  end

  def create_order_fees!
    return unless order_cycle

    calculator.create_order_adjustments_for order
  end

  def tax_enterprise_fees!
    Spree::TaxRate.adjust(order, order.all_adjustments.enterprise_fee)
  end

  def update_line_item_fees!(line_item)
    line_item.adjustments.enterprise_fee.each do |fee|
      fee.update_adjustment!(line_item, force: true)
    end
  end

  def update_order_fees!
    order.adjustments.enterprise_fee.where(adjustable_type: 'Spree::Order').each do |fee|
      fee.update_adjustment!(order, force: true)
    end
  end

  private

  def calculator
    @calculator ||= OpenFoodNetwork::EnterpriseFeeCalculator.new(distributor, order_cycle)
  end

  def provided_by_order_cycle?(line_item)
    @order_cycle_variant_ids ||= order_cycle&.variants&.map(&:id) || []
    @order_cycle_variant_ids.include? line_item.variant_id
  end
end
