require 'open_food_network/permalink_generator'
require 'open_food_network/property_merge'
require 'concerns/product_stock'

Spree::Product.class_eval do
  include PermalinkGenerator
  include ProductStock

  # We have an after_destroy callback on Spree::ProductOptionType. However, if we
  # don't specify dependent => destroy on this association, it is not called. See:
  # https://github.com/rails/rails/issues/7618
  has_many :option_types, through: :product_option_types, dependent: :destroy

  belongs_to :supplier, class_name: 'Enterprise', touch: true
  belongs_to :primary_taxon, class_name: 'Spree::Taxon', touch: true

  delegate_belongs_to :master, :unit_value, :unit_description
  delegate :images_attributes=, :display_as=, to: :master

  validates :supplier, presence: true
  validates :primary_taxon, presence: true
  validates :tax_category_id, presence: true, if: "Spree::Config.products_require_tax_category"

  validates :variant_unit, presence: true
  validates :variant_unit_scale,
            presence: { if: ->(p) { %w(weight volume).include? p.variant_unit } }
  validates :variant_unit_name,
            presence: { if: ->(p) { p.variant_unit == 'items' } }

  after_initialize :set_available_on_to_now, if: :new_record?
  before_validation :sanitize_permalink
  before_save :add_primary_taxon_to_taxons
  after_save :remove_previous_primary_taxon_from_taxons
  after_save :ensure_standard_variant
  after_save :update_units

  # -- Joins
  scope :with_order_cycles_outer, -> {
    joins("
      LEFT OUTER JOIN spree_variants AS o_spree_variants
        ON (o_spree_variants.product_id = spree_products.id)").
      joins("
        LEFT OUTER JOIN exchange_variants AS o_exchange_variants
          ON (o_exchange_variants.variant_id = o_spree_variants.id)").
      joins("
        LEFT OUTER JOIN exchanges AS o_exchanges
          ON (o_exchanges.id = o_exchange_variants.exchange_id)").
      joins("
        LEFT OUTER JOIN order_cycles AS o_order_cycles
          ON (o_order_cycles.id = o_exchanges.order_cycle_id)")
  }

  scope :imported_on, lambda { |import_date|
    import_date = Time.zone.parse import_date if import_date.is_a? String
    import_date = import_date.to_date
    joins(:variants).merge(Spree::Variant.where(import_date: import_date.beginning_of_day..import_date.end_of_day))
  }

  scope :with_order_cycles_inner, -> {
    joins(variants_including_master: { exchanges: :order_cycle })
  }

  scope :visible_for, lambda { |enterprise|
    joins('LEFT OUTER JOIN spree_variants AS o_spree_variants ON (o_spree_variants.product_id = spree_products.id)').
      joins('LEFT OUTER JOIN inventory_items AS o_inventory_items ON (o_spree_variants.id = o_inventory_items.variant_id)').
      where('o_inventory_items.enterprise_id = (?) AND visible = (?)', enterprise, true)
  }

  # -- Scopes
  scope :in_supplier, lambda { |supplier| where(supplier_id: supplier) }

  # Products distributed via the given distributor through an OC
  scope :in_distributor, lambda { |distributor|
    distributor = distributor.respond_to?(:id) ? distributor.id : distributor.to_i

    with_order_cycles_outer.
      where('(o_exchanges.incoming = ? AND o_exchanges.receiver_id = ?)', false, distributor).
      select('distinct spree_products.*')
  }

  scope :in_distributors, lambda { |distributors|
    with_order_cycles_outer.
      where('(o_exchanges.incoming = ? AND o_exchanges.receiver_id IN (?))', false, distributors).
      uniq
  }

  # Products supplied by a given enterprise or distributed via that enterprise through an OC
  scope :in_supplier_or_distributor, lambda { |enterprise|
    enterprise = enterprise.respond_to?(:id) ? enterprise.id : enterprise.to_i

    with_order_cycles_outer.
      where("
        spree_products.supplier_id = ?
        OR (o_exchanges.incoming = ? AND o_exchanges.receiver_id = ?)
      ", enterprise, false, enterprise).
      select('distinct spree_products.*')
  }

  # Products distributed by the given order cycle
  scope :in_order_cycle, lambda { |order_cycle|
    with_order_cycles_inner.
      merge(Exchange.outgoing).
      where('order_cycles.id = ?', order_cycle)
  }

  scope :in_an_active_order_cycle, lambda {
    with_order_cycles_inner.
      merge(OrderCycle.active).
      merge(Exchange.outgoing).
      where('order_cycles.id IS NOT NULL')
  }

  scope :by_producer, -> { joins(:supplier).order('enterprises.name') }
  scope :by_name, -> { order('name') }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
    else
      where('supplier_id IN (?)', user.enterprises.select("enterprises.id"))
    end
  }

  scope :stockable_by, lambda { |enterprise|
    return where('1=0') if enterprise.blank?

    permitted_producer_ids = EnterpriseRelationship.joins(:parent).permitting(enterprise.id)
      .with_permission(:add_to_order_cycle).where(enterprises: { is_primary_producer: true }).pluck(:parent_id)
    return where('spree_products.supplier_id IN (?)', [enterprise.id] | permitted_producer_ids)
  }

  # -- Methods

  # Called by Spree::Product::duplicate before saving.
  def duplicate_extra(_parent)
    # Spree sets the SKU to "COPY OF #{parent sku}".
    master.sku = ''
  end

  def properties_including_inherited
    # Product properties override producer properties
    ps = product_properties.all

    if inherits_properties
      ps = OpenFoodNetwork::PropertyMerge.merge(ps, supplier.producer_properties)
    end

    ps.
      sort_by(&:position).
      map { |pp| { id: pp.property.id, name: pp.property.presentation, value: pp.value } }
  end

  def in_distributor?(distributor)
    self.class.in_distributor(distributor).include? self
  end

  def in_order_cycle?(order_cycle)
    self.class.in_order_cycle(order_cycle).include? self
  end

  def variants_distributed_by(order_cycle, distributor)
    order_cycle.variants_distributed_by(distributor).where(product_id: self)
  end

  # Get the most recent import_date of a product's variants
  def import_date
    variants.map(&:import_date).compact.max
  end

  def variant_unit_option_type
    if variant_unit.present?
      option_type_name = "unit_#{variant_unit}"
      option_type_presentation = variant_unit.capitalize

      Spree::OptionType.find_by(name: option_type_name) ||
        Spree::OptionType.create!(name: option_type_name,
                                  presentation: option_type_presentation)
    end
  end

  def destroy_with_delete_from_order_cycles
    transaction do
      touch_distributors

      ExchangeVariant.
        where('exchange_variants.variant_id IN (?)', variants_including_master.with_deleted.
        select(:id)).destroy_all

      destroy_without_delete_from_order_cycles
    end
  end
  alias_method_chain :destroy, :delete_from_order_cycles

  private

  def set_available_on_to_now
    self.available_on ||= Time.zone.now
  end

  def update_units
    if variant_unit_changed?
      option_types.delete self.class.all_variant_unit_option_types
      option_types << variant_unit_option_type if variant_unit.present?
      variants_including_master.each(&:update_units)
    end
  end

  def touch_distributors
    Enterprise.distributing_products(id).each(&:touch)
  end

  def add_primary_taxon_to_taxons
    taxons << primary_taxon unless taxons.include? primary_taxon
  end

  def remove_previous_primary_taxon_from_taxons
    return unless primary_taxon_id_changed? && primary_taxon_id_was

    taxons.destroy(primary_taxon_id_was)
  end

  def self.all_variant_unit_option_types
    Spree::OptionType.where('name LIKE ?', 'unit_%%')
  end

  def ensure_standard_variant
    if master.valid? && variants.empty?
      variant = master.dup
      variant.product = self
      variant.is_master = false
      variants << variant
    end
  end

  # Override Spree's old save_master method and replace it with the most recent method from spree repository
  # This fixes any problems arising from failing master saves, without the need for a validates_associated on
  # master, while giving us more specific errors as to why saving failed
  def save_master
    if master && (
        master.changed? || master.new_record? || (
          master.default_price && (
            master.default_price.changed? || master.default_price.new_record?
          )
        )
      )
      master.save!
    end

    # If the master cannot be saved, the Product object will get its errors
    # and will be destroyed
  rescue ActiveRecord::RecordInvalid
    master.errors.each do |att, error|
      errors.add(att, error)
    end
    raise
  end

  # Spree creates a permalink already but our implementation fixes an edge case.
  def sanitize_permalink
    if permalink.blank? || permalink_changed?
      requested = permalink.presence || permalink_was.presence || name.presence || 'product'
      self.permalink = create_unique_permalink(requested.parameterize)
    end
  end
end
