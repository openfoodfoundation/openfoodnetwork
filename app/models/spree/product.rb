# frozen_string_literal: true

require 'open_food_network/property_merge'
require 'concerns/product_stock'

# PRODUCTS
# Products represent an entity for sale in a store.
# Products can have variations, called variants
# Products properties include description, permalink, availability,
#   shipping category, etc. that do not change by variant.
#
# MASTER VARIANT
# Every product has one master variant, which stores master price and sku, size and weight, etc.
# The master variant does not have option values associated with it.
# Price, SKU, size, weight, etc. are all delegated to the master variant.
# Contains on_hand inventory levels only when there are no variants for the product.
#
# VARIANTS
# All variants can access the product properties directly (via reverse delegation).
# Inventory units are tied to Variant.
# The master variant can have inventory units, but not option values.
# All other variants have option values and may have inventory units.
# Sum of on_hand each variant's inventory level determine "on_hand" level for the product.
#
module Spree
  class Product < ApplicationRecord
    include PermalinkGenerator
    include ProductStock

    acts_as_paranoid

    searchable_attributes :supplier_id, :primary_taxon_id, :meta_keywords
    searchable_associations :supplier, :properties, :primary_taxon, :variants, :master
    searchable_scopes :active, :with_properties

    has_many :product_option_types, dependent: :destroy
    # We have an after_destroy callback on Spree::ProductOptionType. However, if we
    # don't specify dependent => destroy on this association, it is not called. See:
    # https://github.com/rails/rails/issues/7618
    has_many :option_types, through: :product_option_types, dependent: :destroy
    has_many :product_properties, dependent: :destroy
    has_many :properties, through: :product_properties

    has_many :classifications, dependent: :delete_all
    has_many :taxons, through: :classifications

    belongs_to :tax_category, class_name: 'Spree::TaxCategory'
    belongs_to :shipping_category, class_name: 'Spree::ShippingCategory'
    belongs_to :supplier, class_name: 'Enterprise', touch: true
    belongs_to :primary_taxon, class_name: 'Spree::Taxon', touch: true

    has_one :master,
            -> { where is_master: true },
            class_name: 'Spree::Variant',
            dependent: :destroy

    has_many :variants, -> {
      where(is_master: false).order("spree_variants.position ASC")
    }, class_name: 'Spree::Variant'

    has_many :variants_including_master,
             -> { order("spree_variants.position ASC") },
             class_name: 'Spree::Variant',
             dependent: :destroy

    has_many :prices, -> {
      order('spree_variants.position, spree_variants.id, currency')
    }, through: :variants

    has_many :stock_items, through: :variants

    has_many :supplier_properties, through: :supplier, source: :properties

    scope :with_properties, ->(*property_ids) {
      left_outer_joins(:product_properties).
        left_outer_joins(:supplier_properties).
        where(inherits_properties: true).
        where(producer_properties: { property_id: property_ids }).
        or(
          where(spree_product_properties: { property_id: property_ids })
        )
    }

    delegate_belongs_to :master, :sku, :price, :currency, :display_amount, :display_price, :weight,
                        :height, :width, :depth, :is_master, :cost_currency,
                        :price_in, :amount_in, :unit_value, :unit_description
    delegate :images_attributes=, :display_as=, to: :master

    after_create :set_master_variant_defaults
    after_create :build_variants_from_option_values_hash, if: :option_values_hash
    after_save :save_master

    delegate :images, to: :master, prefix: true
    alias_method :images, :master_images

    has_many :variant_images, -> { order(:position) }, source: :images,
                                                       through: :variants_including_master

    accepts_nested_attributes_for :variants, allow_destroy: true

    validates :name, presence: true
    validates :permalink, presence: true
    validates :price, presence: true, if: proc { Spree::Config[:require_master_price] }
    validates :shipping_category, presence: true

    validates :supplier, presence: true
    validates :primary_taxon, presence: true
    validates :tax_category, presence: true,
                             if: proc { Spree::Config[:products_require_tax_category] }

    validates :variant_unit, presence: true
    validates :unit_value, presence: { if: ->(p) { %w(weight volume).include? p.variant_unit } }
    validates :variant_unit_scale,
              presence: { if: ->(p) { %w(weight volume).include? p.variant_unit } }
    validates :variant_unit_name,
              presence: { if: ->(p) { p.variant_unit == 'items' } }

    attr_accessor :option_values_hash

    accepts_nested_attributes_for :product_properties,
                                  allow_destroy: true,
                                  reject_if: lambda { |pp| pp[:property_name].blank? }

    make_permalink order: :name

    alias :options :product_option_types

    after_initialize :ensure_master
    after_initialize :set_available_on_to_now, if: :new_record?

    before_validation :sanitize_permalink
    before_save :add_primary_taxon_to_taxons
    after_save :remove_previous_primary_taxon_from_taxons
    after_save :ensure_standard_variant
    after_save :update_units

    before_destroy :punch_permalink

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
      joins(:variants).merge(Spree::Variant.
        where(import_date: import_date.beginning_of_day..import_date.end_of_day))
    }

    scope :with_order_cycles_inner, -> {
      joins(variants_including_master: { exchanges: :order_cycle })
    }

    scope :visible_for, lambda { |enterprise|
      joins('
        LEFT OUTER JOIN spree_variants AS o_spree_variants
          ON (o_spree_variants.product_id = spree_products.id)').
        joins('
          LEFT OUTER JOIN inventory_items AS o_inventory_items
            ON (o_spree_variants.id = o_inventory_items.variant_id)').
        where('o_inventory_items.enterprise_id = (?) AND visible = (?)', enterprise, true).
        distinct
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
        distinct
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
        .with_permission(:add_to_order_cycle)
        .where(enterprises: { is_primary_producer: true })
        .pluck(:parent_id)
      return where('spree_products.supplier_id IN (?)', [enterprise.id] | permitted_producer_ids)
    }

    scope :active, lambda {
      where("spree_products.deleted_at IS NULL AND spree_products.available_on <= ?", Time.zone.now)
    }

    def self.group_by_products_id
      group(column_names.map { |col_name| "#{table_name}.#{col_name}" })
    end

    def to_param
      permalink.present? ? permalink : (permalink_was || UrlGenerator.to_url(name))
    end

    def tax_category
      if self[:tax_category_id].nil?
        TaxCategory.find_by(is_default: true)
      else
        TaxCategory.find(self[:tax_category_id])
      end
    end

    # Ensures option_types and product_option_types exist for keys in option_values_hash
    def ensure_option_types_exist_for_values_hash
      return if option_values_hash.nil?

      option_values_hash.keys.map(&:to_i).each do |id|
        option_type_ids << id unless option_type_ids.include?(id)
        unless product_option_types.pluck(:option_type_id).include?(id)
          product_option_types.create(option_type_id: id)
        end
      end
    end

    # for adding products which are closely related to existing ones
    def duplicate
      duplicator = Spree::Core::ProductDuplicator.new(self)
      duplicator.duplicate
    end

    # split variants list into hash which shows mapping of opt value onto matching variants
    # eg categorise_variants_from_option(color) => {"red" -> [...], "blue" -> [...]}
    def categorise_variants_from_option(opt_type)
      return {} unless option_types.include?(opt_type)

      variants.active.group_by { |v| v.option_values.detect { |o| o.option_type == opt_type } }
    end

    def self.like_any(fields, values)
      where fields.map { |field|
        values.map { |value|
          arel_table[field].matches("%#{value}%")
        }.inject(:or)
      }.inject(:or)
    end

    def property(property_name)
      return nil unless prop = properties.find_by(name: property_name)

      product_properties.find_by(property: prop).try(:value)
    end

    def set_property(property_name, property_value)
      ActiveRecord::Base.transaction do
        property = Property.where(name: property_name).first_or_create!(presentation: property_name)
        product_property = ProductProperty.where(product: self,
                                                 property: property).first_or_initialize
        product_property.value = property_value
        product_property.save!
      end
    end

    def total_on_hand
      stock_items.sum(&:count_on_hand)
    end

    # Master variant may be deleted (i.e. when the product is deleted)
    # which would make AR's default finder return nil.
    # This is a stopgap for that little problem.
    def master
      super || variants_including_master.with_deleted.find_by(is_master: true)
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
      return if variant_unit.blank?

      option_type_name = "unit_#{variant_unit}"
      option_type_presentation = variant_unit.capitalize

      Spree::OptionType.find_by(name: option_type_name) ||
        Spree::OptionType.create!(name: option_type_name,
                                  presentation: option_type_presentation)
    end

    def self.all_variant_unit_option_types
      Spree::OptionType.where('name LIKE ?', 'unit_%%')
    end

    def destroy
      transaction do
        touch_distributors

        ExchangeVariant.
          where('exchange_variants.variant_id IN (?)', variants_including_master.with_deleted.
          select(:id)).destroy_all

        super
      end
    end

    private

    # Builds variants from a hash of option types & values
    def build_variants_from_option_values_hash
      ensure_option_types_exist_for_values_hash
      values = option_values_hash.values
      values = values.inject(values.shift) { |memo, value| memo.product(value).map(&:flatten) }

      values.each do |ids|
        variants.create(
          option_value_ids: ids,
          price: master.price
        )
      end
      save
    end

    # ensures the master variant is flagged as such
    def set_master_variant_defaults
      master.is_master = true
    end

    # Here we rescue errors when saving master variants (without the need for a
    #   validates_associated on master) and we get more specific data about the errors
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
      master.errors.each do |error|
        errors.add error.attribute, error.message
      end
      raise
    end

    def ensure_master
      return unless new_record?

      self.master ||= Variant.new
    end

    def punch_permalink
      # Punch permalink with date prefix
      update_attribute :permalink, "#{Time.now.to_i}_#{permalink}"
    end

    def set_available_on_to_now
      self.available_on ||= Time.zone.now
    end

    def update_units
      return unless saved_change_to_variant_unit? || saved_change_to_variant_unit_name?

      option_types.delete self.class.all_variant_unit_option_types
      option_types << variant_unit_option_type if variant_unit.present?
      variants_including_master.each(&:update_units)
    end

    def touch_distributors
      Enterprise.distributing_products(id).each(&:touch)
    end

    def add_primary_taxon_to_taxons
      taxons << primary_taxon unless taxons.include? primary_taxon
    end

    def remove_previous_primary_taxon_from_taxons
      return unless saved_change_to_primary_taxon_id? && primary_taxon_id_before_last_save

      taxons.destroy(primary_taxon_id_before_last_save)
    end

    def ensure_standard_variant
      return unless master.valid? && variants.empty?

      variant = master.dup
      variant.product = self
      variant.is_master = false
      variants << variant
    end

    # Spree creates a permalink already but our implementation fixes an edge case.
    def sanitize_permalink
      return unless permalink.blank? || saved_change_to_permalink? || permalink_changed?

      requested = permalink.presence || permalink_was.presence || name.presence || 'product'
      self.permalink = create_unique_permalink(requested.parameterize)
    end
  end
end
