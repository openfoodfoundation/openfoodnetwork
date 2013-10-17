Spree::ShippingMethod.class_eval do
  has_and_belongs_to_many :distributors, join_table: 'distributors_shipping_methods', :class_name => 'Enterprise', association_foreign_key: 'distributor_id'
  attr_accessible :distributor_ids

  scope :for_distributor, lambda { |distributor|
    joins(:distributors).
    where('enterprises.id = ?', distributor)
  }

  scope :by_distributor, lambda {
    joins(:distributors).
    order('enterprises.name, spree_shipping_methods.name').
    select('enterprises.*, spree_shipping_methods.*')
  }

  def available_to_order_with_distributor_check?(order, display_on=nil)
    available_to_order_without_distributor_check?(order, display_on) &&
      self.distributors.include?(order.distributor)
  end
  alias_method_chain :available_to_order?, :distributor_check

  def adjustment_label
    'Delivery'
  end
end
