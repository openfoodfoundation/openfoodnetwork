Spree::LineItem.class_eval do
  attr_accessible :max_quantity

  def shipping_method
    self.product.shipping_method_for_distributor(self.order.distributor)
  end

  def itemwise_shipping_cost
    order = OpenStruct.new :line_items => [self]
    shipping_method.compute_amount(order)
  end
end
