Spree::Product.class_eval do
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

  attr_accessible :supplier_id, :primary_taxon_id, :distributor_ids, :product_distributions_attributes, :group_buy, :group_buy_unit_size
  attr_accessible :variant_unit, :variant_unit_scale, :variant_unit_name, :unit_value, :unit_description, :notes, :images_attributes, :display_as

  validates_associated :master, message: "^Price and On Hand must be valid"
  validates_presence_of :supplier
  validates :primary_taxon, presence: { message: "^Product Category can't be blank" }

  validates_presence_of :variant_unit, if: :has_variants?
  validates_presence_of :variant_unit_scale,
                        if: -> p { %w(weight volume).include? p.variant_unit }
  validates_presence_of :variant_unit_name,
                        if: -> p { p.variant_unit == 'items' }

  after_initialize :set_available_on_to_now, :if => :new_record?
  after_save :update_units
  after_touch :touch_distributors
  before_save :add_primary_taxon_to_taxons


  # -- Joins
  scope :with_product_distributions_outer, joins('LEFT OUTER JOIN product_distributions ON product_distributions.product_id = spree_products.id')

  scope :with_order_cycles_outer, joins('LEFT OUTER JOIN spree_variants AS o_spree_variants ON (o_spree_variants.product_id = spree_products.id)').
                                  joins('LEFT OUTER JOIN exchange_variants AS o_exchange_variants ON (o_exchange_variants.variant_id = o_spree_variants.id)').
                                  joins('LEFT OUTER JOIN exchanges AS o_exchanges ON (o_exchanges.id = o_exchange_variants.exchange_id)').
                                  joins('LEFT OUTER JOIN order_cycles AS o_order_cycles ON (o_order_cycles.id = o_exchanges.order_cycle_id)')

  scope :with_order_cycles_inner, joins(:variants_including_master => {:exchanges => :order_cycle})


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


  # -- Methods

  def properties_h
    # Product properties override producer properties
    ps = supplier.producer_properties.inject(product_properties) do |properties, property|
      if properties.find { |p| p.property.presentation == property.property.presentation }
        properties
      else
        properties + [property]
      end
    end

    ps.
      sort_by { |pp| pp.position }.
      map { |pp| {presentation: pp.property.presentation, value: pp.value} }
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

  def variants_for(order_cycle, distributor)
    self.variants.where('spree_variants.id IN (?)', order_cycle.variants_distributed_by(distributor))
  end

  # overriding to check self.on_demand as well
  def has_stock?
    has_variants? ? variants.any?(&:in_stock?) : (on_demand || master.in_stock?)
  end

  def has_stock_for_distribution?(order_cycle, distributor)
    # This product has stock for a distribution if it is available on-demand
    # or if one of its variants in the distribution is in stock
    (!has_variants? && on_demand) ||
      variants_distributed_by(order_cycle, distributor).any? { |v| v.in_stock? }
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
      delete_without_delete_from_order_cycles

      ExchangeVariant.where('exchange_variants.variant_id IN (?)', self.variants_including_master_and_deleted).destroy_all
    end
  end
  alias_method_chain :delete, :delete_from_order_cycles


  private

  def set_available_on_to_now
    self.available_on ||= Time.now
  end

  def update_units
    if variant_unit_changed?
      option_types.delete self.class.all_variant_unit_option_types
      option_types << variant_unit_option_type if variant_unit.present?
      variants_including_master.each &:update_units
    end
  end

  def touch_distributors
    Enterprise.distributing_product(self).each(&:touch)
  end

  def add_primary_taxon_to_taxons
    taxons << primary_taxon unless taxons.include? primary_taxon
  end

  def self.all_variant_unit_option_types
    Spree::OptionType.where('name LIKE ?', 'unit_%%')
  end

end
