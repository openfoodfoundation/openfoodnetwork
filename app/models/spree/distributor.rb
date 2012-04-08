module Spree
  class Distributor < ActiveRecord::Base
    set_table_name 'distributors'
    has_many :orders
    belongs_to :country

    validates :name, :pickup_address, :country_id, :city, :post_code, :presence => true
  end
end
