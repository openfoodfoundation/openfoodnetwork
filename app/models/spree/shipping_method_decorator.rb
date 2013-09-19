Spree::ShippingMethod.class_eval do
  belongs_to :distributor, class_name: 'Enterprise'
  attr_accessible :distributor_id

  validates_presence_of :distributor_id

  scope :by_distributor, lambda {
    joins(:distributor).
    order('enterprises.name, spree_shipping_methods.name').
    select('enterprises.*, spree_shipping_methods.*')
  }

  def available_to_order_with_distributor_check?(order, display_on=nil)
    available_to_order_without_distributor_check?(order, display_on) &&
      (order.distributor == self.distributor)
  end
  alias_method_chain :available_to_order?, :distributor_check

  def adjustment_label
    'Delivery'
  end

end
