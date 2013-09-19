Spree::ShippingMethod.class_eval do
  belongs_to :distributor, class_name: 'Enterprise'
  attr_accessible :distributor_id

  validates_presence_of :distributor_id

  def available_to_order_with_distributor_check?(order, display_on=nil)
    available_to_order_without_distributor_check?(order, display_on) &&
      (order.distributor == self.distributor)
  end
  alias_method_chain :available_to_order?, :distributor_check

  def adjustment_label
    'Delivery'
  end

end
