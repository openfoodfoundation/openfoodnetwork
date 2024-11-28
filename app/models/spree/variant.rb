# frozen_string_literal: true

require 'open_food_network/enterprise_fee_calculator'
require 'spree/localized_number'

module Spree
  class Variant < ApplicationRecord
    extend Spree::LocalizedNumber
    include VariantUnits::VariantAndLineItemNaming
    include VariantStock

    self.belongs_to_required_by_default = false

    acts_as_paranoid

    searchable_attributes :sku, :display_as, :display_name, :primary_taxon_id, :supplier_id
    searchable_associations :product, :default_price, :primary_taxon, :supplier
    searchable_scopes :active, :deleted

    NAME_FIELDS = ["display_name", "display_as", "weight", "unit_value", "unit_description"].freeze

    SEARCH_KEY = "#{%w(name
                       meta_keywords
                       variants_display_as
                       variants_display_name
                       variants_supplier_name).join('_or_')}_cont".freeze

    belongs_to :product, -> {
                           with_deleted
                         }, touch: true, class_name: 'Spree::Product', optional: false
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'
    belongs_to :shipping_category, class_name: 'Spree::ShippingCategory', optional: false
    belongs_to :primary_taxon, class_name: 'Spree::Taxon', touch: true, optional: false
    belongs_to :supplier, class_name: 'Enterprise', optional: false, touch: true

    delegate :name, :name=, :description, :description=, :meta_keywords, to: :product

    has_many :inventory_units, inverse_of: :variant, dependent: nil
    has_many :line_items, inverse_of: :variant, dependent: nil

    has_many :stock_items, dependent: :destroy, inverse_of: :variant
    has_many :stock_locations, through: :stock_items
    has_many :images, -> { order(:position) }, as: :viewable,
                                               dependent: :destroy,
                                               class_name: "Spree::Image"
    accepts_nested_attributes_for :images

    has_one :default_price,
            -> { with_deleted.where(currency: CurrentConfig.get(:currency)) },
            class_name: 'Spree::Price',
            dependent: :destroy
    has_many :prices,
             class_name: 'Spree::Price',
             dependent: :destroy
    delegate :display_price, :display_amount, :price, :price=,
             :currency, :currency=,
             to: :find_or_build_default_price

    has_many :exchange_variants, dependent: nil
    has_many :exchanges, through: :exchange_variants
    has_many :variant_overrides, dependent: :destroy
    has_many :inventory_items, dependent: :destroy
    has_many :semantic_links, as: :subject, dependent: :delete_all
    has_many :supplier_properties, through: :supplier, source: :properties

    localize_number :price, :weight

    validates_lengths_from_database
    validate :check_currency
    validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true
    validates :tax_category, presence: true,
                             if: proc { Spree::Config.products_require_tax_category }

    validates :variant_unit, presence: true
    validates :unit_value, presence: true, if: ->(variant) {
      %w(weight volume).include?(variant.variant_unit)
    }
    validates :unit_value, numericality: { greater_than: 0 }, allow_blank: true
    validates :unit_description, presence: true, if: ->(variant) {
      variant.variant_unit.present? && variant.unit_value.nil?
    }
    validates :variant_unit_scale, presence: true, if: ->(variant) {
      %w(weight volume).include?(variant.variant_unit)
    }
    validates :variant_unit_name, presence: true, if: ->(variant) {
      variant.variant_unit == 'items'
    }

    before_validation :set_cost_currency
    before_validation :ensure_shipping_category
    before_validation :ensure_unit_value
    before_validation :update_weight_from_unit_value
    before_validation :convert_variant_weight_to_decimal

    before_save :assign_units, if: ->(variant) {
      variant.new_record? || variant.changed_attributes.keys.intersection(NAME_FIELDS).any?
    }

    after_create :create_stock_items
    around_destroy :destruction
    after_save :save_default_price
    after_save :update_units, if: -> {
      saved_change_to_variant_unit? || saved_change_to_variant_unit_name?
    }

    # default variant scope only lists non-deleted variants
    scope :deleted, -> { where.not(deleted_at: nil) }

    scope :with_order_cycles_inner, -> { joins(exchanges: :order_cycle) }

    scope :in_order_cycle, lambda { |order_cycle|
      with_order_cycles_inner.
        merge(Exchange.outgoing).
        where(order_cycles: { id: order_cycle }).
        select('DISTINCT spree_variants.*')
    }

    scope :in_schedule, lambda { |schedule|
      joins(exchanges: { order_cycle: :schedules }).
        merge(Exchange.outgoing).
        where(schedules: { id: schedule }).
        select('DISTINCT spree_variants.*')
    }

    scope :for_distribution, lambda { |order_cycle, distributor|
      where(spree_variants: { id: order_cycle.variants_distributed_by(distributor).
        select(&:id) })
    }

    scope :visible_for, lambda { |enterprise|
      joins(:inventory_items).
        where(
          'inventory_items.enterprise_id = (?) AND inventory_items.visible = (?)',
          enterprise,
          true
        )
    }

    scope :not_hidden_for, lambda { |enterprise|
      enterprise_id = enterprise&.id.to_i
      return none if enterprise_id < 1

      joins("
        LEFT OUTER JOIN (SELECT *
                           FROM inventory_items
                           WHERE enterprise_id = #{enterprise_id})
          AS o_inventory_items
          ON o_inventory_items.variant_id = spree_variants.id")
        .where("o_inventory_items.id IS NULL OR o_inventory_items.visible = (?)", true)
    }

    scope :with_properties, lambda { |property_ids|
      left_outer_joins(:supplier_properties).
        where(producer_properties: { property_id: property_ids })
    }

    # Define sope as class method to allow chaining with other scopes filtering id.
    # In Rails 3, merging two scopes on the same column will consider only the last scope.
    def self.in_distributor(distributor)
      where(id: ExchangeVariant.select(:variant_id).
                joins(:exchange).
                where('exchanges.incoming = ? AND exchanges.receiver_id = ?', false, distributor))
    end

    def self.indexed
      where(nil).index_by(&:id)
    end

    def self.active(currency = nil)
      # "where(id:" is necessary so that the returned relation has no includes
      # The relation without includes will not be readonly and allow updates on it
      where(spree_variants: { id: joins(:prices).
                                          where(deleted_at: nil).
                                          where('spree_prices.currency' =>
                                            currency || CurrentConfig.get(:currency)).
                                          where.not(spree_prices: { amount: nil }).
                                          select("spree_variants.id") })
    end

    def self.linked_to(semantic_id)
      includes(:semantic_links).references(:semantic_links)
        .where(semantic_links: { semantic_id: }).first
    end

    def tax_category
      super || TaxCategory.find_by(is_default: true)
    end

    def price_with_fees(distributor, order_cycle)
      price + fees_for(distributor, order_cycle)
    end

    def fees_for(distributor, order_cycle)
      OpenFoodNetwork::EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for self
    end

    def fees_by_type_for(distributor, order_cycle)
      OpenFoodNetwork::EnterpriseFeeCalculator.new(distributor, order_cycle).fees_by_type_for self
    end

    def fees_name_by_type_for(distributor, order_cycle)
      OpenFoodNetwork::EnterpriseFeeCalculator.new(distributor,
                                                   order_cycle).fees_name_by_type_for self
    end

    def price_in(currency)
      prices.select{ |price| price.currency == currency }.first ||
        Spree::Price.new(variant_id: id, currency:)
    end

    def amount_in(currency)
      price_in(currency).try(:amount)
    end

    def changed?
      # We consider the variant changed if associated price is changed (it is saved after_save)
      super || default_price.changed?
    end

    # can_supply? is implemented in VariantStock
    def in_stock?(quantity = 1)
      can_supply?(quantity)
    end

    def total_on_hand
      Spree::Stock::Quantifier.new(self).total_on_hand
    end

    # Format as per WeightsAndMeasures
    def variant_unit_with_scale
      # Our code is based upon English based number formatting with a period `.`
      scale_clean = ActiveSupport::NumberHelper.number_to_rounded(variant_unit_scale,
                                                                  precision: nil,
                                                                  significant: false,
                                                                  strip_insignificant_zeros: true,
                                                                  locale: :en)
      [variant_unit, scale_clean].compact_blank.join("_")
    end

    def variant_unit_with_scale=(variant_unit_with_scale)
      values = variant_unit_with_scale.split("_")
      assign_attributes(
        variant_unit: values[0],
        variant_unit_scale: values[1] || nil
      )
    end

    private

    def check_currency
      return unless currency.nil?

      self.currency = CurrentConfig.get(:currency)
    end

    def save_default_price
      default_price.save if default_price && (default_price.changed? || default_price.new_record?)
    end

    def find_or_build_default_price
      default_price || build_default_price
    end

    def set_cost_currency
      self.cost_currency = CurrentConfig.get(:currency) if cost_currency.blank?
    end

    def create_stock_items
      return unless stock_items.empty?

      StockLocation.find_each do |stock_location|
        stock_items.create!(stock_location:)
      end
    end

    def update_weight_from_unit_value
      return unless variant_unit == 'weight' && unit_value.present?

      self.weight = weight_from_unit_value
    end

    def destruction
      transaction do
        # Even tough Enterprise will touch associated variant distributors when touched,
        # the variant will be removed from the exchange by the time it's triggered,
        # so it won't be able to find the deleted variant's distributors.
        # This why we do it here
        touch_distributors

        exchange_variants.reload.destroy_all
        yield
      end
    end

    def ensure_unit_value
      Bugsnag.notify("Trying to set unit_value to NaN") if unit_value&.nan?
      return unless (variant_unit == "items" && unit_value.nil?) || unit_value&.nan?

      self.unit_value = 1.0
    end

    def ensure_shipping_category
      self.shipping_category ||= DefaultShippingCategory.find_or_create
    end

    def convert_variant_weight_to_decimal
      self.weight = weight.to_d
    end

    def touch_distributors
      Enterprise.distributing_variants(id).each(&:touch)
    end
  end
end
