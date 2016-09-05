class Enterprise < ActiveRecord::Base
  SELLS = %w(unspecified none own any)
  ENTERPRISE_SEARCH_RADIUS = 100

  preference :shopfront_message, :text, default: ""
  preference :shopfront_closed_message, :text, default: ""
  preference :shopfront_taxon_order, :string, default: ""
  preference :shopfront_order_cycle_order, :string, default: "orders_close_at"

  # This is hopefully a temporary measure, pending the arrival of multiple named inventories
  # for shops. We need this here to allow hubs to restrict visible variants to only those in
  # their inventory if they so choose
  preference :product_selection_from_inventory_only, :boolean, default: false

  devise :confirmable, reconfirmable: true, confirmation_keys: [ :id, :email ]
  handle_asynchronously :send_confirmation_instructions
  handle_asynchronously :send_on_create_confirmation_instructions
  has_paper_trail only: [:owner_id, :sells], on: [:update]

  self.inheritance_column = nil

  acts_as_gmappable :process_geocoding => false

  has_many :relationships_as_parent, class_name: 'EnterpriseRelationship', foreign_key: 'parent_id', dependent: :destroy
  has_many :relationships_as_child, class_name: 'EnterpriseRelationship', foreign_key: 'child_id', dependent: :destroy
  has_and_belongs_to_many :groups, class_name: 'EnterpriseGroup'
  has_many :producer_properties, foreign_key: 'producer_id'
  has_many :properties, through: :producer_properties
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
  has_many :customers
  has_many :billable_periods
  has_many :inventory_items
  has_many :tag_rules
  has_many :stripe_accounts

  delegate :latitude, :longitude, :city, :state_name, :to => :address

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :producer_properties, allow_destroy: true, reject_if: lambda { |pp| pp[:property_name].blank? }
  accepts_nested_attributes_for :tag_rules, allow_destroy: true, reject_if: lambda { |tag_rule| tag_rule[:preferred_customer_tags].blank? }

  has_attached_file :logo,
    styles: { medium: "300x300>", small: "180x180>", thumb: "100x100>" },
    url:  '/images/enterprises/logos/:id/:style/:basename.:extension',
    path: 'public/images/enterprises/logos/:id/:style/:basename.:extension'

  has_attached_file :promo_image,
    styles: { large: ["1200x260#", :jpg], medium: ["720x156#", :jpg],  thumb: ["100x100>", :jpg] },
    url:  '/images/enterprises/promo_images/:id/:style/:basename.:extension',
    path: 'public/images/enterprises/promo_images/:id/:style/:basename.:extension'

  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/
  validates_attachment_content_type :promo_image, :content_type => /\Aimage\/.*\Z/

  include Spree::Core::S3Support
  supports_s3 :logo
  supports_s3 :promo_image


  validates :name, presence: true
  validate :name_is_unique
  validates :sells, presence: true, inclusion: {in: SELLS}
  validates :address, presence: true, associated: true
  validates :email, presence: true
  validates_presence_of :owner
  validates :permalink, uniqueness: true, presence: true
  validate :shopfront_taxons
  validate :enforce_ownership_limit, if: lambda { owner_id_changed? && !owner_id.nil? }
  validates_length_of :description, :maximum => 255


  before_save :confirmation_check, if: lambda { email_changed? }

  before_validation :initialize_permalink, if: lambda { permalink.nil? }
  before_validation :ensure_owner_is_manager, if: lambda { owner_id_changed? && !owner_id.nil? }
  before_validation :ensure_email_set
  before_validation :set_unused_address_fields
  after_validation :geocode_address

  after_touch :touch_distributors
  after_create :relate_to_owners_enterprises
  # TODO: Later versions of devise have a dedicated after_confirmation callback, so use that
  after_update :welcome_after_confirm, if: lambda { confirmation_token_changed? && confirmation_token.nil? }
  after_create :send_welcome_email, if: lambda { email_is_known? }

  after_rollback :restore_permalink


  scope :by_name, order('name')
  scope :visible, where(visible: true)
  scope :confirmed, where('confirmed_at IS NOT NULL')
  scope :unconfirmed, where('confirmed_at IS NULL')
  scope :activated, where("confirmed_at IS NOT NULL AND sells != 'unspecified'")
  scope :ready_for_checkout, lambda {
    joins(:shipping_methods).
    joins(:payment_methods).
    merge(Spree::PaymentMethod.available).
    select('DISTINCT enterprises.*')
  }
  scope :not_ready_for_checkout, lambda {
    # When ready_for_checkout is empty, ActiveRecord generates the SQL:
    # id NOT IN (NULL)
    # I would have expected this to return all rows, but instead it returns none. To
    # work around this, we use the "OR ?=0" clause to return all rows when there are
    # no enterprises ready for checkout.
    where('id NOT IN (?) OR ?=0',
          Enterprise.ready_for_checkout,
          Enterprise.ready_for_checkout.count)
  }
  scope :is_primary_producer, where(:is_primary_producer => true)
  scope :is_distributor, where('sells != ?', 'none')
  scope :is_hub, where(sells: 'any')
  scope :supplying_variant_in, lambda { |variants| joins(:supplied_products => :variants_including_master).where('spree_variants.id IN (?)', variants).select('DISTINCT enterprises.*') }
  scope :with_supplied_active_products_on_hand, lambda {
    joins(:supplied_products)
      .where('spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0', Time.zone.now)
      .uniq
  }
  scope :with_distributed_active_products_on_hand, lambda {
    joins(:distributed_products)
      .where('spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0', Time.zone.now)
      .uniq
  }

  scope :with_distributed_products_outer,
    joins('LEFT OUTER JOIN product_distributions ON product_distributions.distributor_id = enterprises.id').
    joins('LEFT OUTER JOIN spree_products ON spree_products.id = product_distributions.product_id')
  scope :with_order_cycles_as_supplier_outer,
    joins("LEFT OUTER JOIN exchanges ON (exchanges.sender_id = enterprises.id AND exchanges.incoming = 't')").
    joins('LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)')
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
    where('(product_distributions.product_id IS NOT NULL AND spree_products.deleted_at IS NULL AND spree_products.available_on <= ? AND spree_products.count_on_hand > 0) OR (order_cycles.id IS NOT NULL AND order_cycles.orders_open_at <= ? AND order_cycles.orders_close_at >= ?)', Time.zone.now, Time.zone.now, Time.zone.now).
    select('DISTINCT enterprises.*')
  }

  scope :distributors_with_active_order_cycles, lambda {
    with_order_cycles_as_distributor_outer.
    merge(OrderCycle.active).
    select('DISTINCT enterprises.*')
  }

  scope :distributing_products, lambda { |products|
    # TODO: remove this when we pull out product distributions
    pds = joins("INNER JOIN product_distributions ON product_distributions.distributor_id = enterprises.id").
    where("product_distributions.product_id IN (?)", products).select('DISTINCT enterprises.id')

    exs = joins("INNER JOIN exchanges ON (exchanges.receiver_id = enterprises.id AND exchanges.incoming = 'f')").
    joins('INNER JOIN exchange_variants ON (exchange_variants.exchange_id = exchanges.id)').
    joins('INNER JOIN spree_variants ON (spree_variants.id = exchange_variants.variant_id)').
    where('spree_variants.product_id IN (?)', products).select('DISTINCT enterprises.id')

    where(id: pds | exs)
  }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      joins(:enterprise_roles).where('enterprise_roles.user_id = ?', user.id)
    end
  }
  scope :relatives_of_one_union_others, lambda { |one, others|
    where("
      enterprises.id IN
        (SELECT child_id FROM enterprise_relationships WHERE enterprise_relationships.parent_id=?)
      OR enterprises.id IN
        (SELECT parent_id FROM enterprise_relationships WHERE enterprise_relationships.child_id=?)
      OR enterprises.id IN
        (?)
    ", one, one, others)
  }

  # Force a distinct count to work around relation count issue https://github.com/rails/rails/issues/5554
  def self.distinct_count
    count(distinct: true)
  end

  def activated?
    confirmed_at.present? && sells != 'unspecified'
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
    permalink
  end

  def relatives
    Enterprise.where("
      enterprises.id IN
        (SELECT child_id FROM enterprise_relationships WHERE enterprise_relationships.parent_id=?)
      OR enterprises.id IN
        (SELECT parent_id FROM enterprise_relationships WHERE enterprise_relationships.child_id=?)
    ", self.id, self.id)
  end

  def plus_relatives_and_oc_producers(order_cycles)
    oc_producer_ids = Exchange.in_order_cycle(order_cycles).incoming.pluck :sender_id
    Enterprise.relatives_of_one_union_others(id, oc_producer_ids | [id])
  end

  def relatives_including_self
    Enterprise.where(id: relatives.pluck(:id) | [id])
  end

  def distributors
    self.relatives_including_self.is_distributor
  end

  def suppliers
    self.relatives_including_self.is_primary_producer
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

  def inventory_variants
    if prefers_product_selection_from_inventory_only?
      Spree::Variant.visible_for(self)
    else
      Spree::Variant.not_hidden_for(self)
    end
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

  def is_distributor
    self.sells != "none"
  end

  def is_hub
    self.sells == 'any'
  end

  # Simplify enterprise categories for frontend logic and icons, and maybe other things.
  def category
    # Make this crazy logic human readable so we can argue about it sanely.
    cat = self.is_primary_producer ? "producer_" : "non_producer_"
    cat << "sells_" + self.sells

    # Map backend cases to front end cases.
    case cat
      when "producer_sells_any"
        :producer_hub # Producer hub who sells own and others produce and supplies other hubs.
      when "producer_sells_own"
        :producer_shop # Producer with shopfront and supplies other hubs.
      when "producer_sells_none"
        :producer # Producer only supplies through others.
      when "non_producer_sells_any"
        :hub # Hub selling others products in order cycles.
      when "non_producer_sells_own"
        :hub # Wholesaler selling through own shopfront? Does this need a separate name? Should it exist?
      when "non_producer_sells_none"
        :hub_profile # Hub selling outside the system.
    end
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

  def ready_for_checkout?
    shipping_methods.any? && payment_methods.available.any?
  end

  def self.find_available_permalink(test_permalink)
    test_permalink = test_permalink.parameterize
    test_permalink = "my-enterprise" if test_permalink.blank?
    existing = Enterprise.select(:permalink).order(:permalink).where("permalink LIKE ?", "#{test_permalink}%").map(&:permalink)
    unless existing.include?(test_permalink)
      test_permalink
    else
      used_indices = existing.map do |p|
        p.slice!(/^#{test_permalink}/)
        p.match(/^\d+$/).to_s.to_i
      end.select{ |p| p }
      options = (1..existing.length).to_a - used_indices
      test_permalink + options.first.to_s
    end
  end

  # Based on a devise method, but without adding errors
  def pending_any_confirmation?
    !confirmed? || pending_reconfirmation?
  end

  def shop_trial_expiry
    shop_trial_start_date.andand + Spree::Config[:shop_trial_length_days].days
  end

  def can_invoice?
    abn.present?
  end


  protected

  def devise_mailer
    EnterpriseMailer
  end

  private

  def name_is_unique
    dups = Enterprise.where(name: name)
    dups = dups.where('id != ?', id) unless new_record?

    if dups.any?
      errors.add :name, "has already been taken. If this is your enterprise and you would like to claim ownership, please contact the current manager of this profile at #{dups.first.owner.email}."
    end
  end

  def email_is_known?
    owner.enterprises.confirmed.map(&:email).include?(email)
  end

  def confirmation_check
    # Skip confirmation/reconfirmation if the new email has already been confirmed
    if email_is_known?
      new_record? ? skip_confirmation! : skip_reconfirmation!
    end
  end

  def welcome_after_confirm
    # Send welcome email if we are confirming a newly created enterprise
    # Note: this callback only runs on email confirmation
    if confirmed? && unconfirmed_email.nil? && !unconfirmed_email_changed?
      send_welcome_email
    end
  end

  def send_welcome_email
    Delayed::Job.enqueue WelcomeEnterpriseJob.new(self.id)
  end

  def strip_url(url)
    url.andand.sub(/(https?:\/\/)?/, '')
  end

  def set_unused_address_fields
    address.firstname = address.lastname = address.phone = 'unused' if address.present?
  end

  def geocode_address
    address.geocode if address.andand.changed?
  end

  def ensure_owner_is_manager
    users << owner unless users.include?(owner) || owner.admin?
  end

  def ensure_email_set
    self.email = owner.email if email.blank? && owner.present?
  end

  def enforce_ownership_limit
    unless owner.can_own_more_enterprises?
      errors.add(:owner, "^#{owner.email} is not permitted to own any more enterprises (limit is #{owner.enterprise_limit}).")
    end
  end

  def relate_to_owners_enterprises
    # When a new producer is created, it grants permissions to all pre-existing hubs
    # When a new hub is created,
    # - it grants permissions to all pre-existing hubs
    # - all producers grant permission to it

    enterprises = owner.owned_enterprises.where('enterprises.id != ?', self)

    # We grant permissions to all pre-existing hubs
    hub_permissions = [:add_to_order_cycle]
    hub_permissions << :create_variant_overrides if is_primary_producer
    enterprises.is_hub.each do |enterprise|
      EnterpriseRelationship.create!(parent: self,
                                     child: enterprise,
                                     permissions_list: hub_permissions)
    end

    # All pre-existing producers grant permission to new hubs
    if is_hub
      enterprises.is_primary_producer.each do |enterprise|
        EnterpriseRelationship.create!(parent: enterprise,
                                       child: self,
                                       permissions_list: [:add_to_order_cycle,
                                                          :create_variant_overrides])
      end
    end
  end

  def shopfront_taxons
    unless preferred_shopfront_taxon_order =~ /\A((\d+,)*\d+)?\z/
      errors.add(:shopfront_category_ordering, "must contain a list of taxons.")
    end
  end

  def restore_permalink
    # If the permalink has errors, reset it to it's original value, so we can update the form
    self.permalink = permalink_was if permalink_changed? && errors[:permalink].present?
  end

  def initialize_permalink
    self.permalink = Enterprise.find_available_permalink(name)
  end

  def touch_distributors
    Enterprise.distributing_products(self.supplied_products).
      where('enterprises.id != ?', self.id).
      each(&:touch)
  end
end
