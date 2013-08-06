Spree::LineItem.class_eval do
  attr_accessible :max_quantity

  before_create :set_distribution_fee


  def update_distribution_fee_without_callbacks!(distributor)
    set_distribution_fee(distributor)
    update_column(:distribution_fee, distribution_fee)
    update_column(:shipping_method_name, shipping_method_name)
  end


  private

  def shipping_method(distributor=nil)
    distributor ||= self.order.distributor
    self.product.shipping_method_for_distributor(distributor)
  end

  def set_distribution_fee(distributor=nil)
    order = OpenStruct.new :line_items => [self]
    sm = shipping_method(distributor)

    self.distribution_fee = sm.compute_amount(order)
    self.shipping_method_name = sm.name
  end
end
