class Enterprise < ActiveRecord::Base
  TYPES = %w(full single profile)
  ENTERPRISE_SEARCH_RADIUS = 100

  self.inheritance_column = nil

  acts_as_gmappable :process_geocoding => false

  after_create :send_creation_email

  has_and_belongs_to_many :groups, class_name: 'EnterpriseGroup'
  has_many :producer_properties, foreign_key: 'producer_id'
  has_many :supplied_products, :class_name => 'Spree::Product', :foreign_key => 'supplier_id', :dependent => :destroy
  has_many :distributed_orders, :class_name => 'Spree::Order', :foreign_key => 'distributor_id'
  belongs_to :address, :class_name => 'Spree::Address'
  has_many :product_distributions, :foreign_key => 'distributor_id', :dependent => :destroy
  has_many :distributed_products, :through => :product_distributions, :source => :product
  has_many :enterprise_fees
  has_many :enterprise_roles, :dependent => :destroy
  has_many :users, through: :enterprise_roles
  belongs_to :owner, class_name: 'Spree::User', foreign_key: :owner_id, inverse_of: :owned_enterprises
  has_and_belongs_to_many :payment_methods, join_table: 'distributors_payment_methods', class_name: 'Spree::PaymentMethod', foreign_key: 'distributor_id'
  has_many :distributor_shipping_methods, foreign_key: :distributor_id
  has_many :shipping_methods, through: :distributor_shipping_methods

  delegate :latitude, :longitude, :city, :state_name, :to => :address

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :producer_properties, allow_destroy: true, reject_if: lambda { |pp| pp[:property_name].blank? }

  has_attached_file :logo,
    styles: { medium: "300x300>", small: "180x180>", thumb: "100x100>" },
    url:  '/images/enterprises/logos/:id/:style/:basename.:extension',
    path: 'public/images/enterprises/logos/:id/:style/:basename.:extension'

  has_attached_file :promo_image,
    styles: { large: "1200x260#", thumb: "100x100>" },
    url:  '/images/enterprises/promo_images/:id/:style/:basename.:extension',
    path: 'public/images/enterprises/promo_images/:id/:style/:basename.:extension'

  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/
  validates_attachment_content_type :promo_image, :content_type => /\Aimage\/.*\Z/

  include Spree::Core::S3Support
  supports_s3 :logo
  supports_s3 :promo_image


  validates :name, presence: true
  validates :type, presence: true, inclusion: {in: TYPES}
  validates :address, presence: true, associated: true
  validates_presence_of :owner
  validate :enforce_ownership_limit, if: lambda { owner_id_changed? }

  before_validation :ensure_owner_is_manager, if: lambda { owner_id_changed? }
  before_validation :set_unused_address_fields
  after_validation :geocode_address

  scope :by_name, order('name')
  scope :visible, where(:visible => true)
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
  scope :with_order_cycles_as_distributor_outer,
    joins("LEFT OUTER JOIN exchanges ON (exchanges.receiver_id = enterprises.id AND exchanges.incoming = 'f')").
    joins('LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)')
  scope :with_order_cycles_outer,
    joins("LEFT OUTER JOIN exchanges ON (exchanges.receiver_id = enterprises.id OR exchanges.sender_id = enterprises.id)").
    joins('LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)')

  scope :with_order_cycles_and_exchange_variants_outer,
    with_order_cycles_as_distributor_outer.
    joins('LEFT OUTER JOIN exchange_variants ON (exchange_variants.exchange_id = exchanges.id)').
    joins('LEFT OUTER JOIN spree_variants ON (spree_variants.id = exchange_variants.variant_id)')

  scope :active_distributors, lambda {
    with_distributed_products_outer.with_order_cycles_as_distributor_outer.
    where('(product_distributions.product_id IS NOT NULL AND spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0) OR (order_cycles.id IS NOT NULL AND order_cycles.orders_open_at <= ? AND order_cycles.orders_close_at >= ?)', Time.now, Time.now, Time.now).
    select('DISTINCT enterprises.*')
  }

  scope :distributors_with_active_order_cycles, lambda {
    with_order_cycles_as_distributor_outer.
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

  # Return enterprises that participate in order cycles that user coordinates, sends to or receives from
  scope :accessible_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      with_order_cycles_outer.
      where('order_cycles.id IN (?)', OrderCycle.accessible_by(user)).
      select('DISTINCT enterprises.*')
    end
  }

  def self.find_near(suburb)
    enterprises = []

    unless suburb.nil?
      addresses = Spree::Address.near([suburb.latitude, suburb.longitude], ENTERPRISE_SEARCH_RADIUS, :units => :km).joins(:enterprise).limit(10)
      enterprises = addresses.collect(&:enterprise)
    end

    enterprises
  end

  # Force a distinct count to work around relation count issue https://github.com/rails/rails/issues/5554
  def self.distinct_count
    count(distinct: true)
  end

  def set_producer_property(property_name, property_value)
    transaction do
      property = Spree::Property.where(name: property_name).first_or_create!(presentation: property_name)
      producer_property = ProducerProperty.where(producer_id: id, property_id: property.id).first_or_initialize
      producer_property.value = property_value
      producer_property.save!
    end
  end

  def has_supplied_products_on_hand?
    self.supplied_products.where('count_on_hand > 0').present?
  end

  def supplied_and_active_products_on_hand
    self.supplied_products.where('spree_products.count_on_hand > 0').active
  end

  def active_products_in_order_cycles
    self.supplied_and_active_products_on_hand.in_an_active_order_cycle
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end

  def relatives
    Enterprise.where("
      enterprises.id IN
        (SELECT child_id FROM enterprise_relationships WHERE enterprise_relationships.parent_id=?)
      OR enterprises.id IN
        (SELECT parent_id FROM enterprise_relationships WHERE enterprise_relationships.child_id=?)
    ", self.id, self.id)
  end

  def distributors
    self.relatives.is_distributor
  end

  def suppliers
    self.relatives.is_primary_producer
  end

  def website
    strip_url read_attribute(:website)
  end

  def facebook
    strip_url read_attribute(:facebook)
  end

  def linkedin
    strip_url read_attribute(:linkedin)
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

  def enterprise_category
    # Explanation: I added and extra flag then pared it back to a combo, before realising we allready had one.
    # Short version: meets front end and back end needs, without changing much at all.
    #
    # Ditch is_distributor, add can_supply and swap combo names as below.
    # using profile instead of cant_sell was blocking the non selling supplier case and limiting more than it needed to.
    

    # Make this crazy logic human readable so we can argue about it sanely. 
    # This can be simplified later, like this for readablitlty during changes.
    category = is_primary_producer ? "producer_" : "non_producer_" 
    case type
      when "full"
        category << "sell_all_"
      when "single"
        category << "sell_own_"
      when "profile"
        category << "cant_sell_"
    end
    category << (can_supply ? "can_supply" : "cant_supply")

    # Map backend cases to front end cases.
    case category
      when "producer_sell_all_can_supply"
        "producer_hub" # Producer hub who sells own and others produce and supplies other hubs.
      when "producer_sell_all_cant_supply"
        "producer_hub" # Producer hub who sells own and others products but does not supply other hubs.
      when "producer_sell_own_can_supply"
        "producer_shop" # Producer with shopfront and supplies other hubs.
      when "producer_sell_own_cant_supply"
        "producer_shop" # Producer with shopfront.
      when "producer_cant_sell_can_supply"
        "producer" # Producer selling only through others.
      when "producer_cant_sell_cant_supply"
        "producer_profile" # Producer profile.
        
      when "non_producer_sell_all_can_supply"
        "hub" # Hub selling in products without origin.
      when "non_producer_sell_all_cant_supply"
        "hub" # Regular hub.
      when "non_producer_sell_own_can_supply"
        "hub" # Wholesaler selling through own shopfront and others?
      when "non_producer_sell_own_cant_supply"
        "hub" # Wholesaler selling through own shopfront?
      when "non_producer_cant_sell_can_supply"
        "hub_profile" # Wholesaler selling to others.
      when "non_producer_cant_sell_cant_supply"
        "hub_profile" # Hub with just a profile.
    end
  end

  # TODO: Remove this when flags on enterprises are switched over
  # Obviously this duplicates is_producer currently
  def can_supply
    is_primary_producer && type != "profile" #and has distributors?
  end

  # Return all taxons for all distributed products
  def distributed_taxons
    Spree::Taxon.
      joins(:products).
      where('spree_products.id IN (?)', Spree::Product.in_distributor(self)).
      select('DISTINCT spree_taxons.*')
  end

  # Return all taxons for all supplied products
  def supplied_taxons
    Spree::Taxon.
      joins(:products).
      where('spree_products.id IN (?)', Spree::Product.in_supplier(self)).
      select('DISTINCT spree_taxons.*')
  end

  private

  def send_creation_email
    EnterpriseMailer.creation_confirmation(self).deliver
  end

  def strip_url(url)
    url.andand.sub /(https?:\/\/)?/, ''
  end

  def set_unused_address_fields
    address.firstname = address.lastname = address.phone = 'unused' if address.present?
  end

  def geocode_address
    address.geocode if address.changed?
  end

  def ensure_owner_is_manager
    users << owner unless users.include?(owner) || owner.admin?
  end

  def enforce_ownership_limit
    unless owner.can_own_more_enterprises?
      errors.add(:owner, "^You are not permitted to own own any more enterprises (limit is #{owner.enterprise_limit}).")
    end
  end
end
