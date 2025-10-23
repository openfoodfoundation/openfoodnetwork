# frozen_string_literal: false

class Enterprise < ApplicationRecord
  SELLS = %w(unspecified none own any).freeze
  ENTERPRISE_SEARCH_RADIUS = 100
  # The next Rails version will have named variants but we need to store them
  # ourselves for now.
  LOGO_SIZES = [:thumb, :small, :medium].freeze
  PROMO_IMAGE_SIZES = [:thumb, :medium, :large].freeze
  WHITE_LABEL_LOGO_SIZES = [:default, :mobile].freeze
  VALID_INSTAGRAM_REGEX = %r{\A[a-zA-Z0-9._]{1,30}([^/-]*)\z}

  searchable_attributes :sells, :is_primary_producer, :name
  searchable_associations :properties
  searchable_scopes :is_primary_producer, :is_distributor, :is_hub, :activated, :visible,
                    :ready_for_checkout, :not_ready_for_checkout

  preference :shopfront_message, :text, default: ""
  preference :shopfront_closed_message, :text, default: ""
  preference :shopfront_taxon_order, :string, default: ""
  preference :shopfront_producer_order, :string, default: ""
  preference :shopfront_order_cycle_order, :string, default: "orders_close_at"
  preference :shopfront_product_sorting_method, :string, default: "by_category"
  preference :invoice_order_by_supplier, :boolean, default: false
  preference :product_low_stock_display, :boolean, default: false

  # Allow hubs to restrict visible variants to only those in their inventory
  preference :product_selection_from_inventory_only, :boolean, default: false

  has_paper_trail only: [:owner_id, :sells], on: [:update]

  has_many :relationships_as_parent, class_name: 'EnterpriseRelationship',
                                     foreign_key: 'parent_id',
                                     inverse_of: :parent,
                                     dependent: :destroy
  has_many :relationships_as_child, class_name: 'EnterpriseRelationship',
                                    foreign_key: 'child_id',
                                    inverse_of: :child,
                                    dependent: :destroy
  has_and_belongs_to_many :groups, join_table: 'enterprise_groups_enterprises',
                                   class_name: 'EnterpriseGroup'
  has_many :producer_properties, foreign_key: 'producer_id',
                                 inverse_of: :producer,
                                 dependent: :destroy
  has_many :properties, through: :producer_properties
  has_many :supplied_variants,
           class_name: 'Spree::Variant', foreign_key: 'supplier_id',
           inverse_of: :supplier, dependent: :destroy
  has_many :supplied_products, through: :supplied_variants, source: :product
  has_many :distributed_orders, class_name: 'Spree::Order',
                                foreign_key: 'distributor_id',
                                inverse_of: :distributor,
                                dependent: :restrict_with_error

  belongs_to :address, class_name: 'Spree::Address'
  belongs_to :business_address, optional: true, class_name: 'Spree::Address', dependent: :destroy
  has_many :enterprise_fees, dependent: :restrict_with_error
  has_many :enterprise_roles, dependent: :destroy
  has_many :users, through: :enterprise_roles
  belongs_to :owner, class_name: 'Spree::User',
                     inverse_of: :owned_enterprises
  has_many :distributor_payment_methods,
           inverse_of: :distributor,
           foreign_key: :distributor_id,
           dependent: :restrict_with_error
  has_many :distributor_shipping_methods,
           inverse_of: :distributor,
           foreign_key: :distributor_id,
           dependent: :restrict_with_error
  has_many :payment_methods, through: :distributor_payment_methods
  has_many :shipping_methods, through: :distributor_shipping_methods
  has_many :customers, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :tag_rules, dependent: :destroy
  has_one :stripe_account, dependent: :destroy
  has_many :vouchers, dependent: :restrict_with_error
  has_many :connected_apps, dependent: :destroy
  has_many :dfc_permissions, dependent: :destroy
  has_one :custom_tab, dependent: :destroy

  delegate :latitude, :longitude, :city, :state_name, to: :address

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :business_address, reject_if: :business_address_empty?,
                                                   allow_destroy: true
  accepts_nested_attributes_for :producer_properties, allow_destroy: true,
                                                      reject_if: lambda { |pp|
                                                        pp[:property_name].blank?
                                                      }
  accepts_nested_attributes_for :tag_rules, allow_destroy: true,
                                            reject_if: lambda { |tag_rule|
                                              tag_rule[:preferred_customer_tags].blank?
                                            }
  accepts_nested_attributes_for :custom_tab

  has_one_attached :terms_and_conditions
  has_one_attached :logo, service: image_service do |attachment|
    attachment.variant :thumb, resize_to_fill: [100, 100], crop: [0, 0, 100, 100]
    attachment.variant :small, resize_to_fill: [180, 180], crop: [0, 0, 180, 180]
    attachment.variant :medium, resize_to_fill: [300, 300], crop: [0, 0, 300, 300]
  end
  has_one_attached :promo_image, service: image_service do |attachment|
    attachment.variant :thumb, resize_to_limit: [100, 100]
    attachment.variant :medium, resize_to_fill: [720, 156]
    attachment.variant :large, resize_to_fill: [1200, 260]
  end
  has_one_attached :white_label_logo, service: image_service do |attachment|
    attachment.variant :default, resize_to_fill: [217, 44]
    attachment.variant :mobile,  resize_to_fill: [128, 26]
  end

  validates :logo,
            processable_image: true,
            content_type: %r{\Aimage/(png|jpeg|gif|jpg|svg\+xml|webp)\Z}
  validates :promo_image,
            processable_image: true,
            content_type: %r{\Aimage/(png|jpeg|gif|jpg|svg\+xml|webp)\Z}
  validates :terms_and_conditions, content_type: {
    in: "application/pdf",
    message: I18n.t(:enterprise_terms_and_conditions_type_error),
  }

  validates :name, presence: true
  validate :name_is_unique
  validates :sells, presence: true, inclusion: { in: SELLS }
  validates :address, associated: true
  validates :permalink, uniqueness: true, presence: true
  validate :shopfront_taxons
  validate :shopfront_producers
  validate :enforce_ownership_limit, if: lambda { owner_id_changed? && !owner_id.nil? }
  validates :instagram,
            format: {
              with: VALID_INSTAGRAM_REGEX,
              message: Spree.t('errors.messages.invalid_instagram_url')
            }, allow_blank: true
  validate :validate_white_label_logo_link
  validates :external_billing_id,
            format: { with: /\A\S+\z/ },
            allow_blank: true

  before_validation :initialize_permalink, if: lambda { permalink.nil? }
  before_validation :set_unused_address_fields
  after_validation :ensure_owner_is_manager, if: lambda { owner_id_changed? && !owner_id.nil? }

  after_create :set_default_contact
  after_create :relate_to_owners_enterprises

  after_rollback :restore_permalink
  after_touch :touch_distributors
  after_create_commit :send_welcome_email

  scope :by_name, -> { order('name') }
  scope :visible, -> { where(visible: "public") }
  scope :not_hidden, -> { where.not(visible: "hidden") }
  scope :activated, -> { where("sells != 'unspecified'") }
  scope :ready_for_checkout, lambda {
    joins(:shipping_methods).
      joins(:payment_methods).
      merge(Spree::PaymentMethod.available).
      merge(Spree::ShippingMethod.frontend).
      select('DISTINCT enterprises.*')
  }
  scope :not_ready_for_checkout, lambda {
    # When ready_for_checkout is empty, return all rows when there are no enterprises ready for
    # checkout.
    ready_enterprises = Enterprise.default_scoped.ready_for_checkout.
      except(:select).
      select('DISTINCT enterprises.id')

    if ready_enterprises.any?
      where.not(enterprises: { id: ready_enterprises })
    else
      where(nil)
    end
  }
  scope :is_primary_producer, -> { where("enterprises.is_primary_producer IS TRUE") }
  scope :is_distributor, -> { where.not(sells: 'none') }
  scope :is_hub, -> { where(sells: 'any') }
  scope :supplying_variant_in, lambda { |variants|
    joins(:supplied_variants).
      where(spree_variants: { id: variants }).
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

  scope :distributing_variants, lambda { |variants_ids|
    exchanges = joins("
        INNER JOIN exchanges
          ON (exchanges.receiver_id = enterprises.id AND exchanges.incoming = false)
      ").
      joins('INNER JOIN exchange_variants ON (exchange_variants.exchange_id = exchanges.id)').
      joins('INNER JOIN spree_variants ON (spree_variants.id = exchange_variants.variant_id)').
      where(spree_variants: { id: variants_ids }).select('DISTINCT enterprises.id')

    where(id: exchanges)
  }

  scope :managed_by, lambda { |user|
    if user.admin?
      where(nil)
    else
      joins(:enterprise_roles).where(enterprise_roles: { user_id: user.id })
    end
  }

  scope :parents_of_one_union_others, lambda { |one, others|
    where("
      enterprises.id IN
        (SELECT parent_id FROM enterprise_relationships WHERE enterprise_relationships.child_id=?)
      OR enterprises.id IN
        (?)
      ", one, others)
  }

  def business_address_empty?(attributes)
    attributes_exists = attributes['id'].present?
    attributes_empty = attributes.slice(:company, :address1, :city, :phone,
                                        :zipcode).values.all?(&:blank?)
    attributes.merge!(_destroy: 1) if attributes_exists && attributes_empty
    !attributes_exists && attributes_empty
  end

  # Force a distinct count to work around relation count issue https://github.com/rails/rails/issues/5554
  def self.distinct_count
    count(distinct: true)
  end

  def long_description=(html)
    super(HtmlSanitizer.sanitize_and_enforce_link_target_blank(html))
  end

  def preferred_shopfront_message=(html)
    self.prefers_shopfront_message = HtmlSanitizer.sanitize_and_enforce_link_target_blank(html)
  end

  def preferred_shopfront_closed_message=(html)
    self.prefers_shopfront_closed_message =
      HtmlSanitizer.sanitize_and_enforce_link_target_blank(html)
  end

  def remove_logo=(value)
    self.logo = nil if value == "1"
  end

  def remove_promo_image=(value)
    self.promo_image = nil if value == "1"
  end

  def remove_white_label_logo=(value)
    return unless value == "1"

    self.white_label_logo = nil
    self.white_label_logo_link = nil # Link not needed if there's no logo
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

  def plus_parents_and_order_cycle_producers(order_cycles)
    oc_producer_ids = Exchange.in_order_cycle(order_cycles).incoming.pluck :sender_id
    Enterprise.is_primary_producer.parents_of_one_union_others(id, oc_producer_ids | [id])
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

  def logo_url(name)
    image_url_for(logo, name)
  end

  def promo_image_url(name)
    image_url_for(promo_image, name)
  end

  def white_label_logo_url(name = :default)
    image_url_for(white_label_logo, name)
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

  def twitter
    correct_twitter_url self[:twitter]
  end

  def instagram
    correct_instagram_url self[:instagram]
  end

  def whatsapp_url
    correct_whatsapp_url self[:whatsapp_phone]
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

  def is_producer_only
    is_primary_producer && sells == 'none'
  end

  # Simplify enterprise categories for frontend logic and icons, and maybe other things.
  def category
    # Make this crazy logic human readable so we can argue about it sanely.
    cat = is_primary_producer ? "producer_" : "non_producer_"
    cat << ("sells_#{sells}")

    # Map backend cases to front end cases.
    case cat
    when "producer_sells_any"
      :producer_hub # Producer hub who sells own and others produce and supplies other hubs.
    when "producer_sells_own"
      :producer_shop # Producer with shopfront and supplies other hubs.
    when "producer_sells_none"
      :producer # Producer only supplies through others.
    when "non_producer_sells_any", "non_producer_sells_own"
      # Hub selling others products in order cycles
      # Or Wholesaler selling through own shopfront? Does this need a separate name or even exist?
      :hub
    when "non_producer_sells_none"
      :hub_profile # Hub selling outside the system.
    end
  end

  # Return all taxons for all distributed products
  def distributed_taxons
    Spree::Taxon.
      joins(:products).
      where(spree_products: { id: Spree::Product.in_distributor(self).select(&:id) }).
      select('DISTINCT spree_taxons.*')
  end

  def current_distributed_taxons
    Spree::Taxon
      .select("DISTINCT spree_taxons.*")
      .joins(products: :variants)
      .joins("INNER JOIN (#{current_exchange_variants.to_sql}) \
        AS exchange_variants ON spree_variants.id = exchange_variants.variant_id")
  end

  # Return all taxons for all supplied products
  def supplied_taxons
    Spree::Taxon.
      joins(:products).
      where(spree_products: { id: Spree::Product.in_supplier(self).select(&:id) }).
      select('DISTINCT spree_taxons.*')
  end

  def ready_for_checkout?
    shipping_methods.frontend.any? && payment_methods.available.any?(&:configured?)
  end

  def self.find_available_permalink(test_permalink)
    test_permalink = UrlGenerator.to_url(test_permalink)
    test_permalink = "my-enterprise" if test_permalink.blank?
    existing = Enterprise.
      order(:permalink).
      where("permalink LIKE ?", "#{test_permalink}%").
      pluck(:permalink)

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
    return true unless Spree::Config.enterprise_number_required_on_invoices?

    abn.present?
  end

  def public?
    visible == "public"
  end

  protected

  def devise_mailer
    EnterpriseMailer
  end

  private

  def validate_white_label_logo_link
    return if white_label_logo.blank?

    return if white_label_logo_link.blank?

    white_label_logo_link.strip!
    uri = URI(white_label_logo_link)
    self.white_label_logo_link = "http://#{white_label_logo_link}" if uri.scheme.nil?
  rescue URI::InvalidURIError
    errors.add(:white_label_logo_link, I18n.t(:invalid_url, url: white_label_logo_link))
  end

  def image_url_for(image, name)
    return unless image.variable?

    image_variant_url_for(image.variant(name))
  rescue StandardError => e
    Alert.raise "Enterprise ##{id} #{image.try(:name)} error: #{e.message}"
    Rails.logger.error(e.message)

    nil
  end

  def current_exchange_variants
    ExchangeVariant.joins(exchange: :order_cycle)
      .merge(Exchange.outgoing)
      .select("DISTINCT exchange_variants.variant_id, exchanges.receiver_id AS enterprise_id")
      .where(exchanges: { receiver_id: id })
      .merge(OrderCycle.active.with_distributor(id))
  end

  def name_is_unique
    dups = Enterprise.where(name:)
    dups = dups.where.not(id:) unless new_record?

    errors.add :name, I18n.t(:enterprise_name_error, email: dups.first.owner.email) if dups.any?
  end

  def send_welcome_email
    EnterpriseMailer.welcome(self).deliver_later
  end

  def strip_url(url)
    # Strip protocol and trailing slash
    url&.sub(%r{(https?://)?}, '')&.sub(%r{/\z}, '')
  end

  def correct_whatsapp_url(phone_number)
    phone_number && "https://wa.me/#{phone_number.tr('+ ', '')}"
  end

  def correct_instagram_url(url)
    url && strip_url(url.downcase).sub(%r{(www\.)?instagram.com/}, '').delete("@")
  end

  def correct_twitter_url(url)
    url && strip_url(url).sub(%r{(www\.)?twitter.com/}, '').delete("@")
  end

  def set_unused_address_fields
    if address.present?
      address.firstname = address.lastname = address.phone =
                            address.company = 'unused'
    end
    business_address.first_name = business_address.last_name = 'unused' if business_address.present?
  end

  def ensure_owner_is_manager
    users << owner unless users.include?(owner)
  end

  def enforce_ownership_limit
    return if owner.can_own_more_enterprises?

    errors.add(:owner, I18n.t(:enterprise_owner_error, email: owner.email,
                                                       enterprise_limit: owner.enterprise_limit ))
  end

  def set_default_contact
    update_contact owner_id
  end

  def relate_to_owners_enterprises
    # When a new producer is created, it grants permissions to all pre-existing hubs
    # When a new hub is created,
    # - it grants permissions to all pre-existing hubs
    # - all producers grant permission to it

    enterprises = owner.owned_enterprises.where.not(enterprises: { id: self })

    # We grant permissions to all pre-existing hubs
    hub_permissions = [:add_to_order_cycle]
    hub_permissions << :create_variant_overrides if is_primary_producer
    enterprises.is_hub.each do |enterprise|
      EnterpriseRelationship.create!(parent: self,
                                     child: enterprise,
                                     permissions_list: hub_permissions)
    end

    # All pre-existing producers grant permission to new hubs
    return unless is_hub

    enterprises.is_primary_producer.each do |enterprise|
      EnterpriseRelationship.create!(parent: enterprise,
                                     child: self,
                                     permissions_list: [:add_to_order_cycle,
                                                        :create_variant_overrides])
    end
  end

  def shopfront_taxons
    return if preferred_shopfront_taxon_order =~ /\A((\d+,)*\d+)?\z/

    errors.add(:shopfront_category_ordering, "must contain a list of taxons.")
  end

  def shopfront_producers
    return if preferred_shopfront_producer_order =~ /\A((\d+,)*\d+)?\z/

    errors.add(:shopfront_category_ordering, "must contain a list of producers.")
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
    Enterprise.distributing_variants(supplied_variants.select(:id)).
      where.not(enterprises: { id: }).
      update_all(updated_at: Time.zone.now)
  end
end
