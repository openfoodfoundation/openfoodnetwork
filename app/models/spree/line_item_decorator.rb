Spree::LineItem.class_eval do
  belongs_to :shipping_method

  attr_accessible :max_quantity

  def itemwise_shipping_cost
    order = OpenStruct.new :line_items => [self]
    shipping_method.compute_amount(order)
  end
end
