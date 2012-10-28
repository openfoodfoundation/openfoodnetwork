class Enterprise < ActiveRecord::Base
  has_many :supplied_products, :class_name => 'Spree::Product', :foreign_key => 'supplier_id'
  belongs_to :address, :class_name => 'Spree::Address'

  accepts_nested_attributes_for :address

  validates_presence_of :name, :address
  validates_associated :address

  after_initialize :initialize_country
  before_validation :set_unused_address_fields

  def has_supplied_products_on_hand?
    self.supplied_products.where('count_on_hand > 0').present?
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end


  private

  def initialize_country
    self.address ||= Spree::Address.new
    self.address.country = Spree::Country.find_by_id(Spree::Config[:default_country_id]) if self.address.new_record?
  end

  def set_unused_address_fields
    address.firstname = address.lastname = address.phone = 'unused' if address.present?
  end
end
