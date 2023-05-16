# frozen_string_literal: true

class DistributorShippingMethod < ApplicationRecord
  self.table_name = "distributors_shipping_methods"
  self.belongs_to_required_by_default = true

  belongs_to :shipping_method, class_name: "Spree::ShippingMethod", touch: true
  belongs_to :distributor, class_name: "Enterprise", touch: true
end
