# frozen_string_literal: true

class OrderFeesHandler
  attr_reader :order, :distributor, :order_cycle

  def initialize(order)
    @order = order
    @distributor = order.distributor
    @order_cycle = order.order_cycle
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

  def update_line_item_fees!(line_item)
    line_item.adjustments.enterprise_fee.each do |fee|
      fee.update!(line_item, force: true)
    end
  end

  def update_order_fees!
    order.adjustments.enterprise_fee.where(source_type: 'Spree::Order').each do |fee|
      fee.update!(order, force: true)
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
