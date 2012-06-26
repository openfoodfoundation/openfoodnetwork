module Spree
  class Supplier < ActiveRecord::Base
    self.table_name = 'suppliers'
    has_many :products
    belongs_to :address

    accepts_nested_attributes_for :address

    validates_presence_of :name, :address
    validates_associated :address

    after_initialize :initialize_country
    before_validation :set_unused_address_fields

    def initialize_country
      self.address ||= Address.new
      self.address.country = Country.find_by_id(Spree::Config[:default_country_id]) if self.address.new_record?
    end

    def set_unused_address_fields
      address.firstname = address.lastname = address.phone = 'unused' if address.present?
    end

    def to_param
      "#{id}-#{name.parameterize}"
    end
  end
end
