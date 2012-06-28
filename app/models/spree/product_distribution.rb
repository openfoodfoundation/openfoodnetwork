module Spree
  class ProductDistribution < ActiveRecord::Base
    self.table_name = 'product_distributions'

    belongs_to :product
    belongs_to :distributor
    belongs_to :shipping_method

    validates_uniqueness_of :product_id, :scope => :distributor_id
  end
end
