class ProductDistribution < ActiveRecord::Base
  belongs_to :product, :class_name => 'Spree::Product'
  belongs_to :distributor, :class_name => 'Enterprise'
  belongs_to :shipping_method, :class_name => 'Spree::ShippingMethod'

  validates_presence_of :product_id, :on => :update
  validates_presence_of :distributor_id, :shipping_method_id
  validates_uniqueness_of :product_id, :scope => :distributor_id
end
