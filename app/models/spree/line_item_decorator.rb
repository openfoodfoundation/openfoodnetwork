Spree::LineItem.class_eval do
  belongs_to :shipping_method

  attr_accessible :max_quantity

  before_create :set_itemwise_shipping_method


  def itemwise_shipping_cost
    # When order has not yet been placed, update shipping method in case order
    # has changed to a distributor with a different shipping method
    if %w(cart address delivery resumed).include? self.order.state
      set_itemwise_shipping_method
      save! if shipping_method_id_changed?
    end

    order = OpenStruct.new :line_items => [self]
    shipping_method.compute_amount(order)
  end


  private

  def set_itemwise_shipping_method
    self.shipping_method = self.product.shipping_method_for_distributor(self.order.distributor)
  end
end
