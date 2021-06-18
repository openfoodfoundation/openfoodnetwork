# frozen_string_literal: true

class OrderCycleDistributedVariants
  def initialize(order_cycle, distributor)
    @order_cycle = order_cycle
    @distributor = distributor
  end

  def distributes_order_variants?(order)
    unavailable_order_variants(order).empty?
  end

  def unavailable_order_variants(order)
    order.line_item_variants - available_variants
  end

  def available_variants
    return [] unless @order_cycle

    @order_cycle.variants_distributed_by(@distributor)
  end
end
