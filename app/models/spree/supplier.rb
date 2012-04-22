module Spree
  class Supplier < ActiveRecord::Base
    set_table_name 'suppliers'
    belongs_to :address
    # has_many :orders
    # belongs_to :country
    # belongs_to :state

    # validates :name, :pickup_address, :country_id, :state_id, :city, :post_code, :presence => true

    # after_initialize :initialize_country

    # def initialize_country
      # self.country = Spree::Country.find_by_id(Spree::Config[:default_country_id])
    # end
  end
end
