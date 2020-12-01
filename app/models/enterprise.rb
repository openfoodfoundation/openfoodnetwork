# frozen_string_literal: false

require 'spree/core/s3_support'

class Enterprise < ActiveRecord::Base
  SELLS = %w(unspecified none own any).freeze
  ENTERPRISE_SEARCH_RADIUS = 100

  preference :shopfront_message, :text, default: ""
  preference :shopfront_closed_message, :text, default: ""
  preference :shopfront_taxon_order, :string, default: ""
  preference :shopfront_order_cycle_order, :string, default: "orders_close_at"
  preference :show_customer_names_to_suppliers, :boolean, default: false

  # Allow hubs to restrict visible variants to only those in their inventory
  preference :product_selection_from_inventory_only, :boolean, default: false

  has_paper_trail only: [:owner_id, :sells], on: [:update]

  self.inheritance_column = nil

  has_many :relationships_as_parent, class_name: 'EnterpriseRelationship',
                                     foreign_key: 'parent_id',
                                     dependent: :destroy
  has_many :relationships_as_child, class_name: 'EnterpriseRelationship',
                                    foreign_key: 'child_id',
                                    dependent: :destroy
  has_and_belongs_to_many :groups, join_table: 'enterprise_groups_enterprises',
                                   class_name: 'EnterpriseGroup'
  has_many :producer_properties, foreign_key: 'producer_id'
  has_many :properties, through: :producer_properties
  has_many :supplied_products, class_name: 'Spree::Product',
                               foreign_key: 'supplier_id',
                               dependent: :destroy
  has_many :distributed_orders, class_name: 'Spree::Order', foreign_key: 'distributor_id'
  belongs_to :address, class_name: 'Spree::Address'
  has_many :enterprise_fees
  has_many :enterprise_roles, dependent: :destroy
  has_many :users, through: :enterprise_roles
  belongs_to :owner, class_name: 'Spree::User',
                     foreign_key: :owner_id,
                     inverse_of: :owned_enterprises
  has_and_belongs_to_many :payment_methods, join_table: 'distributors_payment_methods',
                                            class_name: 'Spree::PaymentMethod',
                                            foreign_key: 'distributor_id'
  has_many :distributor_shipping_methods, foreign_key: :distributor_id
  has_many :shipping_methods, through: :distributor_shipping_methods
  has_many :customers
  has_many :inventory_items
  has_many :tag_rules
  has_one :stripe_account, dependent: :destroy

  delegate :latitude, :longitude, :city, :state_name, to: :address

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :producer_properties, allow_destroy: true,
                                                      reject_if: lambda { |pp|
                                                        pp[:property_name].blank?
                                                      }
  accepts_nested_attributes_for :tag_rules, allow_destroy: true,
                                            reject_if: lambda { |tag_rule|
                                              tag_rule[:preferred_customer_tags].blank?
                                            }

  has_attached_file :logo,
                    styles: { medium: "300x300>", small: "180x180>", thumb: "100x100>" },
                    url: '/images/enterprises/logos/:id/:style/:basename.:extension',
                    path: 'public/images/enterprises/logos/:id/:style/:basename.:extension'

  has_attached_file :promo_image,
                    styles: {
                      large: ["1200x260#", :jpg],
                      medium: ["720x156#", :jpg],
                      thumb: ["100x100>", :jpg]
                    },
                    url: '/images/enterprises/promo_images/:id/:style/:basename.:extension',
                    path: 'public/images/enterprises/promo_images/:id/:style/:basename.:extension'
  validates_attachment_content_type :logo, content_type: %r{\Aimage/.*\Z}
  validates_attachment_content_type :promo_image, content_type: %r{\Aimage/.*\Z}

  has_attached_file :terms_and_conditions,
                    url: '/files/enterprises/terms_and_conditions/:id/:basename.:extension',
                    path: 'public/files/enterprises/terms_and_conditions/:id/:basename.:extension'
  validates_attachment_content_type :terms_and_conditions,
                                    content_type: "application/pdf",
                                    message: I18n.t(:enterprise_terms_and_conditions_type_error)

  include Spree::Core::S3Support
  supports_s3 :logo
  supports_s3 :promo_image

  validates :name, presence: true
  validate :name_is_unique
  validates :sells, presence: true, inclusion: { in: SELLS }
  validates :address, presence: true, associated: true
  validates :owner, presence: true
  validates :permalink, uniqueness: true, presence: true
  validate :shopfront_taxons
  validate :enforce_ownership_limit, if: lambda { owner_id_changed? && !owner_id.nil? }

  before_validation :initialize_permalink, if: lambda { permalink.nil? }
  before_validation :set_unused_address_fields
  after_validation :geocode_address
  after_validation :ensure_owner_is_manager, if: lambda { owner_id_changed? && !owner_id.nil? }

  after_touch :touch_distributors
  after_create :set_default_contact
  after_create :relate_to_owners_enterprises
  after_create :send_welcome_email

  after_rollback :restore_permalink

  scope :by_name, -> { order('name') }
  scope :visible, -> { where(visible: true) }
  scope :activated, -> { where("sells != 'unspecified'") }
  scope :ready_for_checkout, lambda {
    joins(:shipping_methods).
      joins(:payment_methods).
      merge(Spree::PaymentMethod.available).
      select('DISTINCT enterprises.*')
  }
  scope :not_ready_for_checkout, lambda {
    # When ready_for_checkout is empty, return all rows when there are no enterprises ready for
    # checkout.
    ready_enterprises = Enterprise.ready_for_checkout.
      except(:select).
      select('DISTINCT enterprises.id')

    if ready_enterprises.any?
      where("enterprises.id NOT IN (?)", ready_enterprises)
    else
      where(nil)
    end
  }
  scope :is_primary_producer, -> { where("enterprises.is_primary_producer IS TRUE") }
  scope :is_distributor, -> { where('sells != ?', 'none') }
  scope :is_hub, -> { where(sells: 'any') }
  scope :supplying_variant_in, lambda { |variants|
    joins(supplied_products: :variants_including_master).
      where('spree_variants.id IN (?)', variants).
      select('DISTINCT enterprises.*')
  }

  scope :with_order_cycles_as_supplier_outer, -> {
    joins("
      LEFT OUTER JOIN exchanges
        ON (exchanges.sender_id = enterprises.id AND exchanges.incoming = 't')").
      joins("LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)")
  }

  scope :with_order_cycles_as_distributor_outer, -> {
    joins("
      LEFT OUTER JOIN exchanges
        ON (exchanges.receiver_id = enterprises.id AND exchanges.incoming = 'f')").
      joins("LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)")
  }

  scope :with_order_cycles_outer, -> {
    joins("
      LEFT OUTER JOIN exchanges
        ON (exchanges.receiver_id = enterprises.id OR exchanges.sender_id = enterprises.id)").
      joins("LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)")
  }

  scope :with_order_cycles_and_exchange_variants_outer, -> {
    with_order_cycles_as_distributor_outer.
      joins("LEFT OUTER JOIN exchange_variants ON (exchange_variants.exchange_id = exchanges.id)").
      joins("LEFT OUTER JOIN spree_variants ON (spree_variants.id = exchange_variants.variant_id)")
  }

  scope :distributors_with_active_order_cycles, lambda {
    with_order_cycles_as_distributor_outer.
      merge(OrderCycle.active).
      select('DISTINCT enterprises.*')
  }

  scope :distributing_products, lambda { |product_ids|
    exchanges = joins("
        INNER JOIN exchanges
          ON (exchanges.receiver_id = enterprises.id AND exchanges.incoming = 'f')
      ").
      joins('INNER JOIN exchange_variants ON (exchange_variants.exchange_id = exchanges.id)').
      joins('INNER JOIN spree_variants ON (spree_variants.id = exchange_variants.variant_id)').
      where('spree_variants.product_id IN (?)', product_ids).select('DISTINCT enterprises.id')

    where(id: exchanges)
  }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
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

  def contact
    contact = users.where(enterprise_roles: { receives_notifications: true }).first
    contact || owner
  end

  def update_contact(user_id)
    enterprise_roles.update_all(["receives_notifications=(user_id=?)", user_id])
  end

  def activated?
    contact.confirmed? && sells != 'unspecified'
  end

  def set_producer_property(property_name, property_value)
    transaction do
      property = Spree::Property.
        where(name: property_name).
        first_or_create!(presentation: property_name)
      producer_property = ProducerProperty.
        where(producer_id: id, property_id: property.id).
        first_or_initialize
      producer_property.value = property_value
      producer_property.save!
    end
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
    ", id, id)
  end

  def plus_relatives_and_oc_producers(order_cycles)
    oc_producer_ids = Exchange.in_order_cycle(order_cycles).incoming.pluck :sender_id
    Enterprise.relatives_of_one_union_others(id, oc_producer_ids | [id])
  end

  def relatives_including_self
    Enterprise.where(id: relatives.pluck(:id) | [id])
  end

  def distributors
    relatives_including_self.is_distributor
  end

  def suppliers
    relatives_including_self.is_primary_producer
  end

  def website
    strip_url self[:website]
  end

  def facebook
    strip_url self[:facebook]
  end

  def linkedin
    strip_url self[:linkedin]
  end

  def inventory_variants
    if prefers_product_selection_from_inventory_only?
      Spree::Variant.visible_for(self)
    else
      Spree::Variant.not_hidden_for(self)
    end
  end

  def distributed_variants
    Spree::Variant.
      joins(:product).
      merge(Spree::Product.in_distributor(self)).
      select('spree_variants.*')
  end

  def is_distributor
    sells != "none"
  end

  def is_hub
    sells == 'any'
  end

  # Simplify enterprise categories for frontend logic and icons, and maybe other things.
  def category
    # Make this crazy logic human readable so we can argue about it sanely.
    cat = is_primary_producer ? "producer_" : "non_producer_"
    cat << "sells_" + sells

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
      :hub # Wholesaler selling through own shopfront? Does this need a separate name or even exist?
    when "non_producer_sells_none"
      :hub_profile # Hub selling outside the system.
    end
  end

  # Return all taxons for all distributed products
  def distributed_taxons
    Spree::Taxon.
      joins(:products).
      where('spree_products.id IN (?)', Spree::Product.in_distributor(self).select(&:id)).
      select('DISTINCT spree_taxons.*')
  end

  def current_distributed_taxons
    Spree::Taxon
      .select("DISTINCT spree_taxons.*")
      .joins(products: :variants_including_master)
      .joins("INNER JOIN (#{current_exchange_variants.to_sql}) \
        AS exchange_variants ON spree_variants.id = exchange_variants.variant_id")
  end

  # Return all taxons for all supplied products
  def supplied_taxons
    Spree::Taxon.
      joins(:products).
      where('spree_products.id IN (?)', Spree::Product.in_supplier(self).select(&:id)).
      select('DISTINCT spree_taxons.*')
  end

  def ready_for_checkout?
    shipping_methods.any? && payment_methods.available.any?
  end

  def self.find_available_permalink(test_permalink)
    test_permalink = test_permalink.parameterize
    test_permalink = "my-enterprise" if test_permalink.blank?
    existing = Enterprise.
      select(:permalink).
      order(:permalink).
      where("permalink LIKE ?", "#{test_permalink}%").
      map(&:permalink)

    if existing.include?(test_permalink)
      used_indices = existing.map do |p|
        p.slice!(/^#{test_permalink}/)
        p.match(/^\d+$/).to_s.to_i
      end.select{ |p| p }
      options = (1..existing.length).to_a - used_indices
      test_permalink + options.first.to_s
    else
      test_permalink
    end
  end

  def can_invoice?
    abn.present?
  end

  protected

  def devise_mailer
    EnterpriseMailer
  end

  private

  def current_exchange_variants
    ExchangeVariant.joins(exchange: :order_cycle)
      .merge(Exchange.outgoing)
      .select("DISTINCT exchange_variants.variant_id, exchanges.receiver_id AS enterprise_id")
      .where("exchanges.receiver_id = ?", id)
      .merge(OrderCycle.active.with_distributor(id))
  end

  def name_is_unique
    dups = Enterprise.where(name: name)
    dups = dups.where('id != ?', id) unless new_record?

    errors.add :name, I18n.t(:enterprise_name_error, email: dups.first.owner.email) if dups.any?
  end

  def send_welcome_email
    WelcomeEnterpriseJob.perform_later(id)
  end

  def strip_url(url)
    url.andand.sub(%r{(https?://)?}, '')
  end

  def set_unused_address_fields
    address.firstname = address.lastname = address.phone = 'unused' if address.present?
  end

  def geocode_address
    address.geocode if address.andand.changed?
  end

  def ensure_owner_is_manager
    users << owner unless users.include?(owner)
  end

  def enforce_ownership_limit
    unless owner.can_own_more_enterprises?
      errors.add(:owner, I18n.t(:enterprise_owner_error, email: owner.email,
                                                         enterprise_limit: owner.enterprise_limit ))
    end
  end

  def set_default_contact
    update_contact owner_id
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
    return unless name

    self.permalink = Enterprise.find_available_permalink(name)
  end

  # Touch distributors without them touching their distributors.
  # We avoid an infinite loop and don't need to touch the whole distributor tree.
  def touch_distributors
    Enterprise.distributing_products(supplied_products.select(:id)).
      where('enterprises.id != ?', id).
      update_all(updated_at: Time.zone.now)
  end
end
