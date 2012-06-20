module Spree
  class Distributor < ActiveRecord::Base
    self.table_name = 'distributors'
    belongs_to :country
    belongs_to :state
    has_and_belongs_to_many :products

    validates :name, :pickup_address, :country_id, :state_id, :city, :post_code, :presence => true

    after_initialize :initialize_country

    def initialize_country
      self.country = Spree::Country.find_by_id(Spree::Config[:default_country_id])
    end

    def to_param
      "#{id}-#{name.parameterize}"
    end
  end
end
