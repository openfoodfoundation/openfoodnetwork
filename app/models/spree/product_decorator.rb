require 'open_food_network/permalink_generator'
require 'open_food_network/property_merge'

Spree::Product.class_eval do
  include PermalinkGenerator
  # We have an after_destroy callback on Spree::ProductOptionType. However, if we
  # don't specify dependent => destroy on this association, it is not called. See:
  # https://github.com/rails/rails/issues/7618
  has_many :option_types, :through => :product_option_types, :dependent => :destroy

  belongs_to :supplier, :class_name => 'Enterprise', touch: true
  belongs_to :primary_taxon, class_name: 'Spree::Taxon'

  has_many :product_distributions, :dependent => :destroy
  has_many :distributors, :through => :product_distributions

  accepts_nested_attributes_for :product_distributions, :allow_destroy => true
  delegate_belongs_to :master, :unit_value, :unit_description
  delegate :images_attributes=, :display_as=, to: :master

  attr_accessible :supplier_id, :primary_taxon_id, :distributor_ids, :product_distributions_attributes
  attr_accessible :group_buy, :group_buy_unit_size, :unit_description, :notes, :images_attributes, :display_as
  attr_accessible :variant_unit, :variant_unit_scale, :variant_unit_name, :unit_value
  attr_accessible :inherits_properties, :sku

  # validates_presence_of :variants, unless: :new_record?, message: "Product must have at least one variant"
  validates_presence_of :supplier
  validates :primary_taxon, presence: { message: I18n.t("validation_msg_product_category_cant_be_blank") }
  validates :tax_category_id, presence: { message: I18n.t("validation_msg_tax") }, if: "Spree::Config.products_require_tax_category"

  validates_presence_of :variant_unit
  validates_presence_of :variant_unit_scale,
                        if: -> p { %w(weight volume).include? p.variant_unit }
  validates_presence_of :variant_unit_name,
                        if: -> p { p.variant_unit == 'items' }

  after_initialize :set_available_on_to_now, :if => :new_record?
  before_validation :sanitize_permalink
  before_save :add_primary_taxon_to_taxons
  after_touch :touch_distributors
  after_save :ensure_standard_variant
  after_save :update_units
  after_save :refresh_products_cache


  # -- Joins
  scope :with_product_distributions_outer, joins('LEFT OUTER JOIN product_distributions ON product_distributions.product_id = spree_products.id')

  scope :with_order_cycles_outer, joins('LEFT OUTER JOIN spree_variants AS o_spree_variants ON (o_spree_variants.product_id = spree_products.id)').
    joins('LEFT OUTER JOIN exchange_variants AS o_exchange_variants ON (o_exchange_variants.variant_id = o_spree_variants.id)').
    joins('LEFT OUTER JOIN exchanges AS o_exchanges ON (o_exchanges.id = o_exchange_variants.exchange_id)').
    joins('LEFT OUTER JOIN order_cycles AS o_order_cycles ON (o_order_cycles.id = o_exchanges.order_cycle_id)')

  scope :with_order_cycles_inner, joins(:variants_including_master => {:exchanges => :order_cycle})

  scope :visible_for, lambda { |enterprise|
    joins('LEFT OUTER JOIN spree_variants AS o_spree_variants ON (o_spree_variants.product_id = spree_products.id)').
      joins('LEFT OUTER JOIN inventory_items AS o_inventory_items ON (o_spree_variants.id = o_inventory_items.variant_id)').
      where('o_inventory_items.enterprise_id = (?) AND visible = (?)', enterprise, true).
      select('DISTINCT spree_products.*')
  }


  # -- Scopes
  scope :in_supplier, lambda { |supplier| where(:supplier_id => supplier) }

  scope :in_any_supplier, lambda { |suppliers|
    where('supplier_id IN (?)', suppliers.map(&:id))
  }

  # Find products that are distributed via the given distributor EITHER through a product distribution OR through an order cycle
  scope :in_distributor, lambda { |distributor|
    distributor = distributor.respond_to?(:id) ? distributor.id : distributor.to_i

    with_product_distributions_outer.with_order_cycles_outer.
      where('product_distributions.distributor_id = ? OR (o_exchanges.incoming = ? AND o_exchanges.receiver_id = ?)', distributor, false, distributor).
      select('distinct spree_products.*')
  }

  scope :in_product_distribution_by, lambda { |distributor|
    distributor = distributor.respond_to?(:id) ? distributor.id : distributor.to_i

    with_product_distributions_outer.
      where('product_distributions.distributor_id = ?', distributor).
      select('distinct spree_products.*')
  }

  # Find products that are supplied by a given enterprise or distributed via that enterprise EITHER through a product distribution OR through an order cycle
  scope :in_supplier_or_distributor, lambda { |enterprise|
    enterprise = enterprise.respond_to?(:id) ? enterprise.id : enterprise.to_i

    with_product_distributions_outer.with_order_cycles_outer.
      where('spree_products.supplier_id = ? OR product_distributions.distributor_id = ? OR (o_exchanges.incoming = ? AND o_exchanges.receiver_id = ?)', enterprise, enterprise, false, enterprise).
      select('distinct spree_products.*')
  }

  # Find products that are distributed by the given order cycle
  scope :in_order_cycle, lambda { |order_cycle| with_order_cycles_inner.
    merge(Exchange.outgoing).
    where('order_cycles.id = ?', order_cycle) }

  scope :in_an_active_order_cycle, lambda { with_order_cycles_inner.
    merge(OrderCycle.active).
    merge(Exchange.outgoing).
    where('order_cycles.id IS NOT NULL') }

  scope :by_producer, joins(:supplier).order('enterprises.name')
  scope :by_name, order('name')

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('supplier_id IN (?)', user.enterprises)
    end
  }

  scope :stockable_by, lambda { |enterprise|
    return where('1=0') if enterprise.blank?
    permitted_producer_ids = EnterpriseRelationship.joins(:parent).permitting(enterprise)
      .with_permission(:add_to_order_cycle).where(enterprises: { is_primary_producer: true }).pluck(:parent_id)
    return where('spree_products.supplier_id IN (?)', [enterprise.id] | permitted_producer_ids)
  }


  # -- Methods

  # Called by Spree::Product::duplicate before saving.
  def duplicate_extra(parent)
    # Spree sets the SKU to "COPY OF #{parent sku}".
    self.master.sku = ''
  end

  def properties_including_inherited
    # Product properties override producer properties
    ps = product_properties.all

    if inherits_properties
      ps = OpenFoodNetwork::PropertyMerge.merge(ps, supplier.producer_properties)
    end

    ps.
      sort_by { |pp| pp.position }.
      map { |pp| {id: pp.property.id, name: pp.property.presentation, value: pp.value} }
  end

  def in_distributor?(distributor)
    self.class.in_distributor(distributor).include? self
  end

  def in_order_cycle?(order_cycle)
    self.class.in_order_cycle(order_cycle).include? self
  end

  def product_distribution_for(distributor)
    self.product_distributions.find_by_distributor_id(distributor)
  end

  # overriding to check self.on_demand as well
  def has_stock?
    has_variants? ? variants.any?(&:in_stock?) : (on_demand || master.in_stock?)
  end

  def has_stock_for_distribution?(order_cycle, distributor)
    # This product has stock for a distribution if it is available on-demand
    # or if one of its variants in the distribution is in stock
    (!has_variants? && on_demand) ||
      variants_distributed_by(order_cycle, distributor).any?(&:in_stock?)
  end

  def variants_distributed_by(order_cycle, distributor)
    order_cycle.variants_distributed_by(distributor).where(product_id: self)
  end

  # Build a product distribution for each distributor
  def build_product_distributions_for_user user
    Enterprise.is_distributor.managed_by(user).each do |distributor|
      unless self.product_distributions.find_by_distributor_id distributor.id
        self.product_distributions.build(:distributor => distributor)
      end
    end
  end

  def variant_unit_option_type
    if variant_unit.present?
      option_type_name = "unit_#{variant_unit}"
      option_type_presentation = variant_unit.capitalize

      Spree::OptionType.find_by_name(option_type_name) ||
        Spree::OptionType.create!(name: option_type_name,
                                  presentation: option_type_presentation)
    end
  end

  def delete_with_delete_from_order_cycles
    transaction do
      OpenFoodNetwork::ProductsCache.product_deleted(self) do
        # Touch supplier and distributors as we would on #destroy
        self.supplier.touch
        touch_distributors

        ExchangeVariant.where('exchange_variants.variant_id IN (?)', self.variants_including_master_and_deleted).destroy_all

        delete_without_delete_from_order_cycles
      end
    end
  end
  alias_method_chain :delete, :delete_from_order_cycles


  def refresh_products_cache
    OpenFoodNetwork::ProductsCache.product_changed self
  end


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
    Enterprise.distributing_products(self).each(&:touch)
  end

  def add_primary_taxon_to_taxons
    taxons << primary_taxon unless taxons.include? primary_taxon
  end

  def self.all_variant_unit_option_types
    Spree::OptionType.where('name LIKE ?', 'unit_%%')
  end

  def ensure_standard_variant
    if master.valid? && variants.empty?
      variant = self.master.dup
      variant.product = self
      variant.is_master = false
      variant.on_demand = self.on_demand
      self.variants << variant
    end
  end

  # Override Spree's old save_master method and replace it with the most recent method from spree repository
  # This fixes any problems arising from failing master saves, without the need for a validates_associated on
  # master, while giving us more specific errors as to why saving failed
  def save_master
    begin
      if master && (master.changed? || master.new_record? || (master.default_price && (master.default_price.changed? || master.default_price.new_record?)))
        master.save!
      end

    # If the master cannot be saved, the Product object will get its errors
    # and will be destroyed
    rescue ActiveRecord::RecordInvalid
      master.errors.each do |att, error|
        self.errors.add(att, error)
      end
      raise
    end
  end

  def sanitize_permalink
    if permalink.blank? || permalink_changed?
      requested = permalink.presence || permalink_was.presence || name.presence || 'product'
      self.permalink = create_unique_permalink(requested.parameterize)
    end
  end
end
