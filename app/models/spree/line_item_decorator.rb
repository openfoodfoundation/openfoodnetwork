require 'open_food_network/scope_variant_to_hub'
require 'open_food_network/variant_and_line_item_naming'

Spree::LineItem.class_eval do
  include OpenFoodNetwork::VariantAndLineItemNaming
  include LineItemBasedAdjustmentHandling
  has_and_belongs_to_many :option_values, join_table: 'spree_option_values_line_items', class_name: 'Spree::OptionValue'

  # Redefining here to add the inverse_of option
  belongs_to :order, class_name: "Spree::Order", inverse_of: :line_items

  # Allows manual skipping of Stock::AvailabilityValidator
  attr_accessor :skip_stock_check

  attr_accessible :max_quantity, :final_weight_volume, :price
  attr_accessible :final_weight_volume, :price, as: :api
  attr_accessible :skip_stock_check

  before_save :calculate_final_weight_volume, if: :quantity_changed?, unless: :final_weight_volume_changed?
  after_save :update_units

  before_destroy :update_inventory_before_destroy

  delegate :product, :unit_description, to: :variant

  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      # Find line items that are from orders distributed by the user or supplied by the user
      joins(variant: :product).
        joins(:order).
        where('spree_orders.distributor_id IN (?) OR spree_products.supplier_id IN (?)', user.enterprises, user.enterprises).
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

  scope :supplied_by, lambda { |enterprise|
    joins(:product).
      where('spree_products.supplier_id = ?', enterprise)
  }
  scope :supplied_by_any, lambda { |enterprises|
    joins(:product).
      where('spree_products.supplier_id IN (?)', enterprises)
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

  def variant
    # Overridden so that LineItems always have access to soft-deleted Variant attributes
    Spree::Variant.unscoped { super }
  end

  def cap_quantity_at_stock!
    scoper.scope(variant)
    return if variant.on_demand

    update_attributes!(quantity: variant.on_hand) if quantity > variant.on_hand
  end

  def has_tax?
    adjustments.included_tax.any?
  end

  def included_tax
    adjustments.included_tax.sum(&:included_tax)
  end

  def tax_rates
    product.tax_category.andand.tax_rates || []
  end

  def price_with_adjustments
    # EnterpriseFee#create_adjustment applies adjustments on line items to their parent order,
    # so line_item.adjustments returns an empty array
    return 0 if quantity.zero?

    line_item_adjustments = OrderAdjustmentsFetcher.new(order).line_item_adjustments(self)

    (price + line_item_adjustments.sum(&:amount) / quantity).round(2)
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

  delegate :display_name, to: :variant

  def unit_value
    return variant.unit_value if quantity == 0 || !final_weight_volume

    final_weight_volume / quantity
  end

  # Overrides Spree version to:
  #   - skip stock check if skip_stock_check flag is active
  #   - skip stock check if requested quantity is zero or negative
  #   - scope variants to hub and thus acivate variant overrides
  def sufficient_stock?
    return true if skip_stock_check
    return true if quantity <= 0

    scoper.scope(variant)
    variant.can_supply?(quantity)
  end

  def scoper
    @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
  end

  private

  def update_inventory_with_scoping
    scoper.scope(variant)
    update_inventory_without_scoping
  end
  alias_method_chain :update_inventory, :scoping

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
