Spree::LineItem.class_eval do
  belongs_to :shipping_method

  attr_accessible :max_quantity

  before_create :set_itemwise_shipping_method


  def itemwise_shipping_cost
    order = OpenStruct.new :line_items => [self]
    shipping_method.compute_amount(order)
  end

  def update_itemwise_shipping_method_without_callbacks!(distributor)
    update_column(:shipping_method_id, self.product.shipping_method_for_distributor(distributor).id)
  end


  private

  def set_itemwise_shipping_method
    self.shipping_method = self.product.shipping_method_for_distributor(self.order.distributor)
  end
end
