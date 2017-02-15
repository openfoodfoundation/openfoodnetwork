class DistributionChangeValidator

  def initialize order
    @order = order
  end

  def can_change_to_distributor?(distributor)
    # Distributor may not be changed once an item has been added to the cart/order, unless all items are available from the specified distributor
    @order.line_items.empty? || all_available_distributors.include?(distributor)
  end

  def can_change_to_distribution?(distributor, order_cycle)
    (@order.line_item_variants - variants_available_for_distribution(distributor, order_cycle)).empty?
  end

  def variants_available_for_distribution(distributor, order_cycle)
    product_distribution_variants = distributor.andand.product_distribution_variants || []
    order_cycle_variants = order_cycle.andand.variants_distributed_by(distributor) || []

    product_distribution_variants + order_cycle_variants
  end

  def distributor_available_for?(product)
    @order.nil? || available_distributors_for(product).present?
  end

  def order_cycle_available_for?(product)
    @order.nil? || !product_requires_order_cycle(product) || available_order_cycles_for(product).present?
  end

  def available_distributors_for(product)
    distributors = Enterprise.distributing_products(product)

    if @order.andand.line_items.present?
      distributors = available_distributors(distributors)
    end

    distributors
  end

  def available_order_cycles_for(product)
    order_cycles = OrderCycle.distributing_product(product)

    if @order.andand.line_items.present?
      order_cycles = available_order_cycles(order_cycles)
    end

    order_cycles
  end

  def product_requires_order_cycle(product)
    product.product_distributions.blank?
  end

  def all_available_distributors
    @all_available_distributors ||= (available_distributors(Enterprise.all) || [])
  end

  def available_distributors enterprises
    enterprises.select do |e|
      (@order.line_item_variants - e.distributed_variants).empty?
    end
  end

  def available_order_cycles order_cycles
    order_cycles.select do |oc|
      (@order.line_item_variants - oc.distributed_variants).empty?
    end
  end
end
