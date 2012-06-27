module Spree
  class ProductDistribution < ActiveRecord::Base
    self.table_name = 'product_distributions'

    belongs_to :product
    belongs_to :distributor
    belongs_to :shipping_method
  end
end
