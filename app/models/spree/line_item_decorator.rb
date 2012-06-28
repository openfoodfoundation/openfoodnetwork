Spree::LineItem.class_eval do
  def itemwise_shipping_cost
    self.product.shipping_cost_for_distributor(self.order.distributor)
  end
end
