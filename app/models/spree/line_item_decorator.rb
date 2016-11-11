require 'open_food_network/variant_and_line_item_naming'

Spree::LineItem.class_eval do
  include OpenFoodNetwork::VariantAndLineItemNaming
  has_and_belongs_to_many :option_values, join_table: 'spree_option_values_line_items', class_name: 'Spree::OptionValue'

  # Redefining here to add the inverse_of option
  belongs_to :order, :class_name => "Spree::Order", inverse_of: :line_items

  attr_accessible :max_quantity, :final_weight_volume, :price
  attr_accessible :final_weight_volume, :price, :as => :api

  before_save :calculate_final_weight_volume, if: :quantity_changed?, unless: :final_weight_volume_changed?
  after_save :update_units

  delegate :unit_description, to: :variant

  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      # Find line items that are from orders distributed by the user or supplied by the user
      joins(:variant => :product).
        joins(:order).
        where('spree_orders.distributor_id IN (?) OR spree_products.supplier_id IN (?)', user.enterprises, user.enterprises).
        select('spree_line_items.*')
    end
  }

  scope :supplied_by, lambda { |enterprise|
    joins(:product).
      where('spree_products.supplier_id = ?', enterprise)
  }
  scope :supplied_by_any, lambda { |enterprises|
    joins(:product).
      where('spree_products.supplier_id IN (?)', enterprises)
  }

  scope :with_tax, joins(:adjustments).
    where('spree_adjustments.originator_type = ?', 'Spree::TaxRate').
    select('DISTINCT spree_line_items.*')

  # Line items without a Spree::TaxRate-originated adjustment
  scope :without_tax, joins("LEFT OUTER JOIN spree_adjustments ON (spree_adjustments.adjustable_id=spree_line_items.id AND spree_adjustments.adjustable_type = 'Spree::LineItem' AND spree_adjustments.originator_type='Spree::TaxRate')").
    where('spree_adjustments.id IS NULL')


  def cap_quantity_at_stock!
    scoper.scope(variant)
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
    return 0 if quantity == 0
    (price + order.adjustments.where(source_id: id).sum(&:amount) / quantity).round(2)
  end

  def single_display_amount_with_adjustments
    Spree::Money.new(price_with_adjustments, { :currency => currency })
  end

  def amount_with_adjustments
    # We calculate from price_with_adjustments here rather than building our own value because
    # rounding errors can produce discrepencies of $0.01.
    price_with_adjustments * quantity
  end

  def display_amount_with_adjustments
    Spree::Money.new(amount_with_adjustments, { :currency => currency })
  end

  def display_included_tax
    Spree::Money.new(included_tax, { :currency => currency })
  end

  def display_name
    variant.display_name
  end

  def unit_value
    return 0 if quantity == 0
    (final_weight_volume || 0) / quantity
  end

  # MONKEYPATCH of Spree method
  # Enables scoping of variant to hub/shop, stock drawn down from inventory
  def update_inventory
    return true unless order.completed?

    scoper.scope(variant) # this line added

    if new_record?
      Spree::InventoryUnit.increase(order, variant, quantity)
    elsif old_quantity = self.changed_attributes['quantity']
      if old_quantity < quantity
        Spree::InventoryUnit.increase(order, variant, (quantity - old_quantity))
      elsif old_quantity > quantity
        Spree::InventoryUnit.decrease(order, variant, (old_quantity - quantity))
      end
    end
  end

  # MONKEYPATCH of Spree method
  # Enables scoping of variant to hub/shop, stock replaced to inventory
  def remove_inventory
    return true unless order.completed?

    scoper.scope(variant) # this line added

    Spree::InventoryUnit.decrease(order, variant, quantity)
  end

  private

  def scoper
	  return @scoper unless @scoper.nil?
	  @scoper = OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
  end

  def calculate_final_weight_volume
    if final_weight_volume.present? && quantity_was > 0
      self.final_weight_volume = final_weight_volume * quantity / quantity_was
    elsif variant.andand.unit_value.present?
      self.final_weight_volume = variant.andand.unit_value * quantity
    end
  end
end
