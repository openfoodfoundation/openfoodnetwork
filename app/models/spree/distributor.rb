module Spree
  class Distributor < ActiveRecord::Base
    self.table_name = 'distributors'
    belongs_to :pickup_address, :foreign_key => 'pickup_address_id', :class_name => 'Spree::Address'
    has_many :orders

    has_many :product_distributions
    has_many :products, :through => :product_distributions

    accepts_nested_attributes_for :pickup_address

    validates_presence_of :name, :pickup_address
    validates_associated :pickup_address

    scope :by_name, order('name')

    after_initialize :initialize_country
    before_validation :set_unused_address_fields

    def initialize_country
      self.pickup_address ||= Address.new
      self.pickup_address.country = Country.find_by_id(Spree::Config[:default_country_id]) if self.pickup_address.new_record?
    end

    def set_unused_address_fields
      pickup_address.firstname = pickup_address.lastname = pickup_address.phone = 'unused' if pickup_address.present?
    end

    def to_param
      "#{id}-#{name.parameterize}"
    end
  end
end
