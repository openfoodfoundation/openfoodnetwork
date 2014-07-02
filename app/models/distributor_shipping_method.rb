class DistributorShippingMethod < ActiveRecord::Base
  self.table_name = "distributors_shipping_methods" 
  belongs_to :shipping_method, class_name: Spree::ShippingMethod
  belongs_to :distributor, class_name: Enterprise, touch: true
end
