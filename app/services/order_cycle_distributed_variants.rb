class OrderCycleDistributedVariants

  def initialize order
    @order = order
  end

  def can_change_to_distribution?(distributor, order_cycle)
    (@order.line_item_variants - variants_available_for_distribution(distributor, order_cycle)).empty?
  end

  def variants_available_for_distribution(distributor, order_cycle)
    return [] unless order_cycle
    order_cycle.variants_distributed_by(distributor)
  end
end
