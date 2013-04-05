class DistributorChangeValidator
  
  def initialize order
    @order = order
  end
  
  def can_change_distributor?
    # Distributor may not be changed once an item has been added to the cart/order
    @order.line_items.empty?
  end

  def can_change_to_distributor? distributor
    # Distributor may not be changed once an item has been added to the cart/order, unless all items are available from the specified distributor
    @order.line_items.empty? || (available_distributors(Enterprise.all) || []).include?(distributor)
  end
  
  def available_distributors enterprises
    enterprises.select do |e|
      (@order.line_item_variants - e.distributed_variants).empty?
    end
  end
end
