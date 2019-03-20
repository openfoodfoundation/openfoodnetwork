class DistributionChangeValidator

  def initialize order
    @order = order
  end

  def can_change_to_distribution?(distributor, order_cycle)
    (@order.line_item_variants - variants_available_for_distribution(distributor, order_cycle)).empty?
  end

  def variants_available_for_distribution(distributor, order_cycle)
    product_distribution_variants = []
    product_distribution_variants = distributor.product_distribution_variants if distributor
    order_cycle_variants = []
    order_cycle_variants = order_cycle.variants_distributed_by(distributor) if order_cycle

    product_distribution_variants + order_cycle_variants
  end
end
