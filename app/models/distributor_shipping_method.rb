# frozen_string_literal: true

class DistributorShippingMethod < ApplicationRecord
  self.table_name = "distributors_shipping_methods"

  belongs_to :shipping_method, class_name: "Spree::ShippingMethod", touch: true
  belongs_to :distributor, class_name: "Enterprise", touch: true
end
