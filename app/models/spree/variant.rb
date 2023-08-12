# frozen_string_literal: true

require 'open_food_network/enterprise_fee_calculator'
require 'variant_units/variant_and_line_item_naming'
require 'concerns/variant_stock'
require 'spree/localized_number'

module Spree
  class Variant < ApplicationRecord
    extend Spree::LocalizedNumber
    include VariantUnits::VariantAndLineItemNaming
    include VariantStock

    self.belongs_to_required_by_default = false

    acts_as_paranoid

    searchable_attributes :sku, :display_as, :display_name
    searchable_associations :product, :default_price
    searchable_scopes :active, :deleted

    NAME_FIELDS = ["display_name", "display_as", "weight", "unit_value", "unit_description"].freeze

    SEARCH_KEY = "#{%w(name
                       meta_keywords
                       variants_display_as
                       variants_display_name
                       supplier_name).join('_or_')}_cont".freeze

    belongs_to :product, -> { with_deleted }, touch: true, class_name: 'Spree::Product'
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'

    delegate_belongs_to :product, :name, :description, :shipping_category_id,
                        :meta_keywords, :shipping_category

    has_many :inventory_units, inverse_of: :variant
    has_many :line_items, inverse_of: :variant

    has_many :stock_items, dependent: :destroy, inverse_of: :variant
    has_many :stock_locations, through: :stock_items
    has_many :stock_movements
    has_many :images, -> { order(:position) }, as: :viewable,
                                               dependent: :destroy,
                                               class_name: "Spree::Image"
    accepts_nested_attributes_for :images

    has_one :default_price,
            -> { with_deleted.where(currency: Spree::Config[:currency]) },
            class_name: 'Spree::Price',
            dependent: :destroy
    has_many :prices,
             class_name: 'Spree::Price',
             dependent: :destroy
    delegate_belongs_to :default_price, :display_price, :display_amount,
                        :price, :price=, :currency

    has_many :exchange_variants
    has_many :exchanges, through: :exchange_variants
    has_many :variant_overrides
    has_many :inventory_items

    localize_number :price, :weight

    validate :check_currency
    validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true
    validates :tax_category, presence: true,
                             if: proc { Spree::Config[:products_require_tax_category] }

    validates :unit_value, presence: true, if: ->(variant) {
      %w(weight volume).include?(variant.product&.variant_unit)
    }

    validates :unit_value, numericality: { greater_than: 0 }

    validates :unit_description, presence: true, if: ->(variant) {
      variant.product&.variant_unit.present? && variant.unit_value.nil?
    }

    before_validation :set_cost_currency
    before_validation :ensure_unit_value
    before_validation :update_weight_from_unit_value, if: ->(v) { v.product.present? }

    before_save :convert_variant_weight_to_decimal
    before_save :assign_units, if: ->(variant) {
      variant.new_record? || variant.changed_attributes.keys.intersection(NAME_FIELDS).any?
    }

    after_create :create_stock_items
    around_destroy :destruction
    after_save :save_default_price

    # default variant scope only lists non-deleted variants
    scope :deleted, lambda { where('deleted_at IS NOT NULL') }

    scope :with_order_cycles_inner, -> { joins(exchanges: :order_cycle) }

    scope :in_order_cycle, lambda { |order_cycle|
      with_order_cycles_inner.
        merge(Exchange.outgoing).
        where('order_cycles.id = ?', order_cycle).
        select('DISTINCT spree_variants.*')
    }

    scope :in_schedule, lambda { |schedule|
      joins(exchanges: { order_cycle: :schedules }).
        merge(Exchange.outgoing).
        where(schedules: { id: schedule }).
        select('DISTINCT spree_variants.*')
    }

    scope :for_distribution, lambda { |order_cycle, distributor|
      where('spree_variants.id IN (?)', order_cycle.variants_distributed_by(distributor).
        select(&:id))
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

    scope :stockable_by, lambda { |enterprise|
      return where("1=0") if enterprise.blank?

      joins(:product).
        where(spree_products: { id: Spree::Product.stockable_by(enterprise).pluck(:id) })
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
      where("spree_variants.id in (?)", joins(:prices).
                                          where(deleted_at: nil).
                                          where('spree_prices.currency' =>
                                            currency || Spree::Config[:currency]).
                                          where('spree_prices.amount IS NOT NULL').
                                          select("spree_variants.id"))
    end

    def tax_category
      if self[:tax_category_id].nil?
        TaxCategory.find_by(is_default: true)
      else
        TaxCategory.find(self[:tax_category_id])
      end
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
        Spree::Price.new(variant_id: id, currency: currency)
    end

    def amount_in(currency)
      price_in(currency).try(:amount)
    end

    # can_supply? is implemented in VariantStock
    def in_stock?(quantity = 1)
      can_supply?(quantity)
    end

    def total_on_hand
      Spree::Stock::Quantifier.new(self).total_on_hand
    end

    private

    def check_currency
      return unless currency.nil?

      self.currency = Spree::Config[:currency]
    end

    def save_default_price
      default_price.save if default_price && (default_price.changed? || default_price.new_record?)
    end

    def set_cost_currency
      self.cost_currency = Spree::Config[:currency] if cost_currency.blank?
    end

    def create_stock_items
      StockLocation.all.find_each do |stock_location|
        stock_location.propagate_variant(self)
      end
    end

    def update_weight_from_unit_value
      return unless product.variant_unit == 'weight' && unit_value.present?

      self.weight = weight_from_unit_value
    end

    def destruction
      exchange_variants.reload.destroy_all
      yield
    end

    def ensure_unit_value
      Bugsnag.notify("Trying to set unit_value to NaN") if unit_value&.nan?
      return unless (product&.variant_unit == "items" && unit_value.nil?) || unit_value&.nan?

      self.unit_value = 1.0
    end

    def convert_variant_weight_to_decimal
      self.weight = weight.to_d
    end
  end
end
