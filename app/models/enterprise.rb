class Enterprise < ActiveRecord::Base
  ENTERPRISE_SEARCH_RADIUS = 100

  acts_as_gmappable :process_geocoding => false

  has_and_belongs_to_many :groups, class_name: 'EnterpriseGroup'
  has_many :supplied_products, :class_name => 'Spree::Product', :foreign_key => 'supplier_id', :dependent => :destroy
  has_many :distributed_orders, :class_name => 'Spree::Order', :foreign_key => 'distributor_id'
  belongs_to :address, :class_name => 'Spree::Address'
  has_many :product_distributions, :foreign_key => 'distributor_id', :dependent => :destroy
  has_many :distributed_products, :through => :product_distributions, :source => :product
  has_many :enterprise_fees
  has_many :enterprise_roles, :dependent => :destroy
  has_many :users, through: :enterprise_roles
  has_and_belongs_to_many :payment_methods, join_table: 'distributors_payment_methods', class_name: 'Spree::PaymentMethod', foreign_key: 'distributor_id'
  has_and_belongs_to_many :shipping_methods, join_table: 'distributors_shipping_methods', class_name: 'Spree::ShippingMethod', foreign_key: 'distributor_id'

  delegate :latitude, :longitude, :city, :state_name, :to => :address

  accepts_nested_attributes_for :address
  has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"
  has_attached_file :promo_image, :styles => { :large => "570x380>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"

  validates_presence_of :name
  validates_presence_of :address
  validates_associated :address

  after_initialize :initialize_country
  before_validation :set_unused_address_fields
  after_validation :geocode_address

  scope :by_name, order('name')
  scope :is_primary_producer, where(:is_primary_producer => true)
  scope :is_distributor, where(:is_distributor => true)
  scope :supplying_variant_in, lambda { |variants| joins(:supplied_products => :variants_including_master).where('spree_variants.id IN (?)', variants).select('DISTINCT enterprises.*') }
  scope :with_supplied_active_products_on_hand, lambda {
    joins(:supplied_products)
      .where('spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0', Time.now)
      .uniq
  }
  scope :with_distributed_active_products_on_hand, lambda {
    joins(:distributed_products)
      .where('spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0', Time.now)
      .uniq
  }

  scope :with_distributed_products_outer,
    joins('LEFT OUTER JOIN product_distributions ON product_distributions.distributor_id = enterprises.id').
    joins('LEFT OUTER JOIN spree_products ON spree_products.id = product_distributions.product_id')
  scope :with_order_cycles_outer,
    joins("LEFT OUTER JOIN exchanges ON (exchanges.receiver_id = enterprises.id AND exchanges.incoming = 'f')").
    joins('LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)')

  scope :with_order_cycles_and_exchange_variants_outer,
    with_order_cycles_outer.
    joins('LEFT OUTER JOIN exchange_variants ON (exchange_variants.exchange_id = exchanges.id)').
    joins('LEFT OUTER JOIN spree_variants ON (spree_variants.id = exchange_variants.variant_id)')

  scope :active_distributors, lambda {
    with_distributed_products_outer.with_order_cycles_outer.
    where('(product_distributions.product_id IS NOT NULL AND spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0) OR (order_cycles.id IS NOT NULL AND order_cycles.orders_open_at <= ? AND order_cycles.orders_close_at >= ?)', Time.now, Time.now, Time.now).
    select('DISTINCT enterprises.*')
  }

  scope :distributors_with_active_order_cycles, lambda {
    with_order_cycles_outer.
    merge(OrderCycle.active).
    select('DISTINCT enterprises.*')
  }

  scope :distributing_product, lambda { |product|
    with_distributed_products_outer.with_order_cycles_and_exchange_variants_outer.
    where('product_distributions.product_id = ? OR spree_variants.product_id = ?', product, product).
    select('DISTINCT enterprises.*')
  }
  scope :distributing_any_product_of, lambda { |products|
    with_distributed_products_outer.with_order_cycles_and_exchange_variants_outer.
    where('product_distributions.product_id IN (?) OR spree_variants.product_id IN (?)', products, products).
    select('DISTINCT enterprises.*')
  }
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      joins(:enterprise_roles).where('enterprise_roles.user_id = ?', user.id)
    end
  }


  # Force a distinct count to work around relation count issue https://github.com/rails/rails/issues/5554
  def self.distinct_count
    count(distinct: true)
  end

  def self.find_near(suburb)
    enterprises = []

    unless suburb.nil?
      addresses = Spree::Address.near([suburb.latitude, suburb.longitude], ENTERPRISE_SEARCH_RADIUS, :units => :km).joins(:enterprise).limit(10)
      enterprises = addresses.collect(&:enterprise)
    end

    enterprises
  end

  def has_supplied_products_on_hand?
    self.supplied_products.where('count_on_hand > 0').present?
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end

  def distributed_variants
    Spree::Variant.joins(:product).merge(Spree::Product.in_distributor(self)).select('spree_variants.*')
  end

  def product_distribution_variants
    Spree::Variant.joins(:product).merge(Spree::Product.in_product_distribution_by(self)).select('spree_variants.*')
  end

  def available_variants
    Spree::Variant.joins(:product => :product_distributions).where('product_distributions.distributor_id=?', self.id)
  end

  private

  def initialize_country
    self.address ||= Spree::Address.new
    self.address.country = Spree::Country.find_by_id(Spree::Config[:default_country_id]) if self.address.new_record?
  end

  def set_unused_address_fields
    address.firstname = address.lastname = address.phone = 'unused' if address.present?
  end

  def geocode_address
    address.geocode if address.changed?
  end
end
