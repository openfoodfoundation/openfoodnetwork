# frozen_string_literal: true

module Spree
  class ShippingMethodZone < ApplicationRecord
    self.table_name = "spree_shipping_methods_zones"

    belongs_to :shipping_method, class_name: 'Spree::ShippingMethod'
    belongs_to :zone, class_name: 'Spree::Zone'
  end
end
