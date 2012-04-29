module Spree
  class Supplier < ActiveRecord::Base
    set_table_name 'suppliers'
    belongs_to :address
    has_many :products

    # validates :name, :pickup_address, :country_id, :state_id, :city, :post_code, :presence => true
  end
end
