# frozen_string_literal: true

require 'open_food_network/property_merge'
# TODO update description

# PRODUCTS
# Products represent an entity for sale in a store.
# Products can have variations, called variants
# Products properties include description, permalink, availability,
#   shipping category, etc. that do not change by variant.
#
# MASTER VARIANT
# Every product has one master variant, which stores master price and sku, size and weight, etc.
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
    include ProductStock
    include LogDestroyPerformer

    self.belongs_to_required_by_default = false

    acts_as_paranoid

    searchable_attributes :meta_keywords, :sku
    searchable_associations :properties, :variants
    searchable_scopes :active, :with_properties

    has_one :image, class_name: "Spree::Image", as: :viewable, dependent: :destroy

    has_many :product_properties, dependent: :destroy
    has_many :properties, through: :product_properties
    has_many :variants, -> { order("spree_variants.id ASC") }, class_name: 'Spree::Variant',
                                                               dependent: :destroy

    has_many :prices, -> { order('spree_variants.id, currency') }, through: :variants

    has_many :stock_items, through: :variants
    has_many :variant_images, -> { order(:position) }, source: :images,
                                                       through: :variants

    validates_lengths_from_database
    validates :name, presence: true

    validates :variant_unit, presence: true
    validates :unit_value, numericality: {
      greater_than: 0,
      if: ->(p) { p.variant_unit.in?(%w(weight volume)) && new_record? }
    }
    validates :variant_unit_scale,
              presence: { if: ->(p) { %w(weight volume).include? p.variant_unit } }
    validates :variant_unit_name,
              presence: { if: ->(p) { p.variant_unit == 'items' } }
    validate :validate_image
    validates :price, numericality: { greater_than_or_equal_to: 0, if: ->{ new_record? } }

    accepts_nested_attributes_for :variants, allow_destroy: true
    accepts_nested_attributes_for :image
    accepts_nested_attributes_for :product_properties,
                                  allow_destroy: true,
                                  reject_if: ->(pp) { pp[:property_name].blank? }

    # Transient attributes used temporarily when creating a new product,
    # these values are persisted on the product's variant
    attr_accessor :price, :display_as, :unit_value, :unit_description, :tax_category_id,
                  :shipping_category_id, :primary_taxon_id, :supplier_id

    after_create :ensure_standard_variant
    after_update :touch_supplier, if: :saved_change_to_primary_taxon_id?
    around_destroy :destruction
    after_save :update_units
    after_touch :touch_supplier

    # -- Scopes
    scope :with_properties, ->(*property_ids) {
      left_outer_joins(:product_properties).
        where(inherits_properties: true).
        where(spree_product_properties: { property_id: property_ids })
    }

    scope :with_order_cycles_outer, lambda {
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
        where(import_date: import_date.all_day))
    }

    scope :with_order_cycles_inner, -> { joins(variants: { exchanges: :order_cycle }) }

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

    scope :in_supplier, lambda { |supplier|
      distinct.joins(:variants).where(spree_variants: { supplier: })
    }

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

    # Products distributed by the given order cycle
    scope :in_order_cycle, lambda { |order_cycle|
      with_order_cycles_inner.
        merge(Exchange.outgoing).
        where(order_cycles: { id: order_cycle })
    }

    scope :in_an_active_order_cycle, lambda {
      with_order_cycles_inner.
        merge(OrderCycle.active).
        merge(Exchange.outgoing).
        where.not(order_cycles: { id: nil })
    }

    scope :by_producer, -> { joins(variants: :supplier).order('enterprises.name') }
    scope :by_name, -> { order('spree_products.name') }

    scope :managed_by, lambda { |user|
      if user.has_spree_role?('admin')
        where(nil)
      else
        in_supplier(user.enterprises)
      end
    }

    scope :active, lambda { where(spree_products: { deleted_at: nil }) }

    def self.group_by_products_id
      group(column_names.map { |col_name| "#{table_name}.#{col_name}" })
    end

    # for adding products which are closely related to existing ones
    def duplicate
      duplicator = Spree::Core::ProductDuplicator.new(self)
      duplicator.duplicate
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
                                                 property:).first_or_initialize
        product_property.value = property_value
        product_property.save!
      end
    end

    def total_on_hand
      stock_items.sum(&:count_on_hand)
    end

    def properties_including_inherited
      # Product properties override producer properties
      ps = product_properties.all

      if inherits_properties
        # NOTE: Set the supplier as the first variant supplier. If variants have different supplier,
        # result might not be correct
        supplier = variants.first.supplier
        ps = OpenFoodNetwork::PropertyMerge.merge(ps, supplier&.producer_properties || [])
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

    def destruction
      transaction do
        touch_distributors

        ExchangeVariant.
          where(exchange_variants: { variant_id: variants.with_deleted.
          select(:id) }).destroy_all

        yield
      end
    end

    def ensure_standard_variant
      return unless variants.empty?

      variant = Spree::Variant.new
      variant.product = self
      variant.price = price
      variant.display_as = display_as
      variant.unit_value = unit_value
      variant.unit_description = unit_description
      variant.tax_category_id = tax_category_id
      variant.shipping_category_id = shipping_category_id
      variant.primary_taxon_id = primary_taxon_id
      variant.supplier_id = supplier_id
      variants << variant
    end

    # Format as per WeightsAndMeasures (todo: re-orgnaise maybe after product/variant refactor)
    def variant_unit_with_scale
      scale_clean = ActiveSupport::NumberHelper.number_to_rounded(variant_unit_scale,
                                                                  precision: nil,
                                                                  strip_insignificant_zeros: true)
      [variant_unit, scale_clean].compact_blank.join("_")
    end

    def variant_unit_with_scale=(variant_unit_with_scale)
      values = variant_unit_with_scale.split("_")
      assign_attributes(
        variant_unit: values[0],
        variant_unit_scale: values[1] || nil
      )
    end

    # Remove any unsupported HTML.
    def description
      HtmlSanitizer.sanitize(super)
    end

    # Remove any unsupported HTML.
    def description=(html)
      super(HtmlSanitizer.sanitize(html))
    end

    private

    def update_units
      return unless saved_change_to_variant_unit? || saved_change_to_variant_unit_name?

      variants.each do |v|
        if v.persisted?
          v.update_units
        else
          v.assign_units
        end
      end
    end

    def touch_supplier
      return if variants.empty?

      # Assume the product supplier is the supplier of the first variant
      # Will breack if product has mutiple variants with different supplier
      first_variant = variants.first

      # The variant is invalid if no supplier is present, but this method can be triggered when
      # importing product. In this scenario the variant has not been updated with the supplier yet
      # hence the check.
      first_variant.supplier.touch if first_variant.supplier.present?
    end

    def touch_distributors
      Enterprise.distributing_products(id).each(&:touch)
    end

    def validate_image
      return if image.blank? || !image.changed? || image.valid?

      errors.add(:base, I18n.t('spree.admin.products.image_not_processable'))
    end
  end
end
