Spree::LineItem.class_eval do
  def itemwise_shipping_cost
    shipping_method = self.product.shipping_method_for_distributor(self.order.distributor)
    order = OpenStruct.new :line_items => [self]
    shipping_method.compute_amount(order)
  end
end
