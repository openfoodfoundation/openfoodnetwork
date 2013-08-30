Spree::ShippingMethod.class_eval do
  belongs_to :distributor, class_name: 'Enterprise'
  attr_accessible :distributor_id

  validates_presence_of :distributor_id
end
