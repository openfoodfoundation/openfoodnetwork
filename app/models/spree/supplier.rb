module Spree
  class Supplier < ActiveRecord::Base
    self.table_name = 'suppliers'
    has_many :products
    belongs_to :country
    belongs_to :state

    validates :name, :address, :country_id, :state_id, :city, :postcode, :presence => true

    after_initialize :initialize_country

    def initialize_country
      self.country = Spree::Country.find_by_id(Spree::Config[:default_country_id])
    end
  end
end
