class Distributor < ActiveRecord::Base
  belongs_to :pickup_address, :foreign_key => 'pickup_address_id', :class_name => 'Spree::Address'
  has_many :orders, :class_name => 'Spree::Order'

  has_many :product_distributions, :dependent => :destroy
  has_many :products, :through => :product_distributions

  accepts_nested_attributes_for :pickup_address

  validates_presence_of :name, :pickup_address
  validates_associated :pickup_address

  scope :by_name, order('name')
  scope :with_active_products_on_hand, lambda { joins(:products).where('spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0', Time.now).select('distinct(distributors.*)') }

  after_initialize :initialize_country
  before_validation :set_unused_address_fields

  def initialize_country
    self.pickup_address ||= Spree::Address.new
    self.pickup_address.country = Spree::Country.find_by_id(Spree::Config[:default_country_id]) if self.pickup_address.new_record?
  end

  def set_unused_address_fields
    pickup_address.firstname = pickup_address.lastname = pickup_address.phone = 'unused' if pickup_address.present?
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end
end
