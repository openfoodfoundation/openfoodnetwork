class DistributorChangeValidator
  
  def initialize order
    @order = order
  end

  def can_change_distributor?
    # Distributor may not be changed once an item has been added to the cart/order
    @order.line_items.empty? || available_distributors(Enterprise.all).length > 1
  end

  def can_change_to_distributor? distributor
    # Distributor may not be changed once an item has been added to the cart/order, unless all items are available from the specified distributor
    @order.line_items.empty? || (available_distributors(Enterprise.all) || []).include?(distributor)
  end

  def product_compatible_with_current_order(product)
    @order.nil? || available_distributors_for(product).present?
  end

  def available_distributors_for(product)
    distributors = Enterprise.distributing_product(product)

    if @order.andand.line_items.present?
      distributors = available_distributors(distributors)
    end

    distributors
  end

  def available_distributors enterprises
    enterprises.select do |e|
      (@order.line_item_variants - e.distributed_variants).empty?
    end
  end
end
