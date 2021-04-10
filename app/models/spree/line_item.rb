# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'
require 'variant_units/variant_and_line_item_naming'

module Spree
  class LineItem < ActiveRecord::Base
    include VariantUnits::VariantAndLineItemNaming
    include LineItemStockChanges

    belongs_to :order, class_name: "Spree::Order", inverse_of: :line_items
    belongs_to :variant, -> { with_deleted }, class_name: "Spree::Variant"
    belongs_to :tax_category, class_name: "Spree::TaxCategory"

    has_one :product, through: :variant
    has_many :adjustments, as: :adjustable, dependent: :destroy

    has_and_belongs_to_many :option_values, join_table: 'spree_option_values_line_items',
                                            class_name: 'Spree::OptionValue'

    before_validation :adjust_quantity
    before_validation :copy_price
    before_validation :copy_tax_category

    validates :variant, presence: true
    validates :quantity, numericality: {
      only_integer: true,
      greater_than: -1,
      message: Spree.t('validation.must_be_int')
    }
    validates :price, numericality: true
    validates_with Stock::AvailabilityValidator

    before_save :update_inventory
    before_save :calculate_final_weight_volume, if: :quantity_changed?,
                                                unless: :final_weight_volume_changed?
    after_save :update_order
    after_save :update_units
    before_destroy :update_inventory_before_destroy
    after_destroy :update_order

    delegate :product, :unit_description, :display_name, to: :variant

    attr_accessor :skip_stock_check # Allows manual skipping of Stock::AvailabilityValidator
    attr_accessor :target_shipment

    # -- Scopes
    scope :managed_by, lambda { |user|
      if user.has_spree_role?('admin')
        where(nil)
      else
        # Find line items that are from orders distributed by the user or supplied by the user
        joins(variant: :product).
          joins(:order).
          where('spree_orders.distributor_id IN (?) OR spree_products.supplier_id IN (?)',
                user.enterprises, user.enterprises).
          select('spree_line_items.*')
      end
    }

    scope :in_orders, lambda { |orders|
      where(order_id: orders)
    }

    # Find line items that are from order sorted by variant name and unit value
    scope :sorted_by_name_and_unit_value, -> {
      joins(variant: :product).
        reorder("
          lower(spree_products.name) asc,
            lower(spree_variants.display_name) asc,
            spree_variants.unit_value asc")
    }

    scope :from_order_cycle, lambda { |order_cycle|
      joins(order: :order_cycle).
        where('order_cycles.id = ?', order_cycle)
    }

    # Here we are simply joining the line item to its variant and product
    # We dont use joins here to avoid the default scopes,
    #   and with that, include deleted variants and deleted products
    scope :supplied_by_any, lambda { |enterprises|
      product_ids = Spree::Product.unscoped.where(supplier_id: enterprises).select(:id)
      variant_ids = Spree::Variant.unscoped.where(product_id: product_ids).select(:id)
      where("spree_line_items.variant_id IN (?)", variant_ids)
    }

    scope :with_tax, -> {
      joins(:adjustments).
        where('spree_adjustments.originator_type = ?', 'Spree::TaxRate').
        select('DISTINCT spree_line_items.*')
    }

    # Line items without a Spree::TaxRate-originated adjustment
    scope :without_tax, -> {
      joins("
        LEFT OUTER JOIN spree_adjustments
          ON (spree_adjustments.adjustable_id=spree_line_items.id
            AND spree_adjustments.adjustable_type = 'Spree::LineItem'
            AND spree_adjustments.originator_type='Spree::TaxRate')").
        where('spree_adjustments.id IS NULL')
    }

    def copy_price
      return unless variant

      self.price = variant.price if price.nil?
      self.currency = variant.currency if currency.nil?
    end

    def copy_tax_category
      return unless variant

      self.tax_category = variant.product.tax_category
    end

    def amount
      price * quantity
    end
    alias total amount

    def single_money
      Spree::Money.new(price, currency: currency)
    end
    alias single_display_amount single_money

    def money
      Spree::Money.new(amount, currency: currency)
    end
    alias display_total money
    alias display_amount money

    def adjust_quantity
      self.quantity = 0 if quantity.nil? || quantity < 0
    end

    # Here we skip stock check if skip_stock_check flag is active,
    #   we skip stock check if requested quantity is zero or negative,
    #   and we scope variants to hub and thus acivate variant overrides.
    def sufficient_stock?
      return true if skip_stock_check
      return true if quantity <= 0

      scoper.scope(variant)
      variant.can_supply?(quantity)
    end

    def insufficient_stock?
      !sufficient_stock?
    end

    def assign_stock_changes_to=(shipment)
      @preferred_shipment = shipment
    end

    def cap_quantity_at_stock!
      scoper.scope(variant)
      return if variant.on_demand

      update!(quantity: variant.on_hand) if quantity > variant.on_hand
    end

    def has_tax?
      adjustments.tax.any?
    end

    def included_tax
      adjustments.tax.inclusive.sum(:amount)
    end

    def tax_rates
      product.tax_category.andand.tax_rates || []
    end

    def price_with_adjustments
      # EnterpriseFee#create_adjustment applies adjustments on line items to their parent order,
      # so line_item.adjustments returns an empty array
      return 0 if quantity.zero?

      fees = adjustments.enterprise_fee.sum(:amount)

      (price + fees / quantity).round(2)
    end

    def single_display_amount_with_adjustments
      Spree::Money.new(price_with_adjustments, currency: currency)
    end

    def amount_with_adjustments
      # We calculate from price_with_adjustments here rather than building our own value because
      # rounding errors can produce discrepencies of $0.01.
      price_with_adjustments * quantity
    end

    def display_amount_with_adjustments
      Spree::Money.new(amount_with_adjustments, currency: currency)
    end

    def display_included_tax
      Spree::Money.new(included_tax, currency: currency)
    end

    def unit_value
      return variant.unit_value if quantity == 0 || !final_weight_volume

      final_weight_volume / quantity
    end

    def unit_price_price_and_unit
      unit_price = UnitPrice.new(variant)
      Spree::Money.new(price_with_adjustments / unit_price.denominator).to_html +
        "&nbsp;/&nbsp;".html_safe + unit_price.unit
    end

    def scoper
      @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
    end

    private

    def update_inventory
      return unless changed?

      scoper.scope(variant)
      Spree::OrderInventory.new(order).verify(self, target_shipment)
    end

    def update_order
      return unless saved_change_to_quantity? || destroyed?

      # update the order totals, etc.
      order.create_tax_charge!
      order.update!
    end

    def update_inventory_before_destroy
      # This is necessary before destroying the line item
      #   so that update_inventory will restore stock to the variant
      self.quantity = 0

      update_inventory

      # This is necessary after updating inventory
      #   because update_inventory may delete the last shipment in the order
      #   and that makes update_order fail if we don't reload the shipments
      order.shipments.reload
    end

    def calculate_final_weight_volume
      if final_weight_volume.present? && quantity_was > 0
        self.final_weight_volume = final_weight_volume * quantity / quantity_was
      elsif variant.andand.unit_value.present?
        self.final_weight_volume = variant.andand.unit_value * quantity
      end
    end
  end
end
