module Spree
  class ProductDistribution < ActiveRecord::Base
    self.table_name = 'product_distributions'

    belongs_to :product
    belongs_to :distributor
    belongs_to :shipping_method

    validates_presence_of :product_id, :on => :update
    validates_presence_of :distributor_id, :shipping_method_id
    validates_uniqueness_of :product_id, :scope => :distributor_id
  end
end
