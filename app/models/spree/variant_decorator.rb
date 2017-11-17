require 'open_food_network/enterprise_fee_calculator'
require 'open_food_network/variant_and_line_item_naming'
require 'open_food_network/products_cache'

Spree::Variant.class_eval do
  extend Spree::LocalizedNumber
  # Remove method From Spree, so method from the naming module is used instead
  # This file may be double-loaded in delayed job environment, so we check before
  # removing the Spree method to prevent error.
  remove_method :options_text if instance_methods(false).include? :options_text
  include OpenFoodNetwork::VariantAndLineItemNaming


  has_many :exchange_variants
  has_many :exchanges, through: :exchange_variants
  has_many :variant_overrides
  has_many :inventory_items

  attr_accessible :unit_value, :unit_description, :images_attributes, :display_as, :display_name
  accepts_nested_attributes_for :images

  validates_presence_of :unit_value,
    if: -> v { %w(weight volume).include? v.product.andand.variant_unit }

  validates_presence_of :unit_description,
    if: -> v { v.product.andand.variant_unit.present? && v.unit_value.nil? }

  before_validation :update_weight_from_unit_value, if: -> v { v.product.present? }
  after_save :update_units
  after_save :refresh_products_cache
  around_destroy :destruction


  scope :with_order_cycles_inner, joins(exchanges: :order_cycle)

  scope :not_deleted, where(deleted_at: nil)
  scope :in_stock, where('spree_variants.count_on_hand > 0 OR spree_variants.on_demand=?', true)
  scope :in_order_cycle, lambda { |order_cycle|
    with_order_cycles_inner.
      merge(Exchange.outgoing).
      where('order_cycles.id = ?', order_cycle).
      select('DISTINCT spree_variants.*')
  }

  scope :in_schedule, lambda { |schedule|
    joins(exchanges: { order_cycle: :schedule}).
      merge(Exchange.outgoing).
      where(schedules: { id: schedule}).
      select('DISTINCT spree_variants.*')
  }

  scope :for_distribution, lambda { |order_cycle, distributor|
    where('spree_variants.id IN (?)', order_cycle.variants_distributed_by(distributor))
  }

  scope :visible_for, lambda { |enterprise|
    joins(:inventory_items).where('inventory_items.enterprise_id = (?) AND inventory_items.visible = (?)', enterprise, true)
  }

  scope :not_hidden_for, lambda { |enterprise|
    return where("1=0") unless enterprise.present?
    joins("LEFT OUTER JOIN (SELECT * from inventory_items WHERE enterprise_id = #{sanitize enterprise.andand.id}) AS o_inventory_items ON o_inventory_items.variant_id = spree_variants.id")
      .where("o_inventory_items.id IS NULL OR o_inventory_items.visible = (?)", true)
  }

  localize_number :price, :cost_price, :weight

  scope :stockable_by, lambda { |enterprise|
    return where("1=0") unless enterprise.present?
    joins(:product).where(spree_products: { id: Spree::Product.stockable_by(enterprise).pluck(:id) })
  }

  # Define sope as class method to allow chaining with other scopes filtering id.
  # In Rails 3, merging two scopes on the same column will consider only the last scope.
  def self.in_distributor(distributor)
    where(id: ExchangeVariant.select(:variant_id).
              joins(:exchange).
              where('exchanges.incoming = ? AND exchanges.receiver_id = ?', false, distributor)
         )
  end

  def self.indexed
    Hash[
      scoped.map { |v| [v.id, v] }
    ]
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

  def delete
    if product.variants == [self] # Only variant left on product
      errors.add :product, I18n.t(:spree_variant_product_error)
      false
    else
      transaction do
        self.update_column(:deleted_at, Time.zone.now)
        ExchangeVariant.where(variant_id: self).destroy_all
        self
      end
    end
  end

  def refresh_products_cache
    if is_master?
      product.refresh_products_cache
    else
      OpenFoodNetwork::ProductsCache.variant_changed self
    end
  end


  private

  def update_weight_from_unit_value
    self.weight = weight_from_unit_value if self.product.variant_unit == 'weight' && unit_value.present?
  end

  def destruction
    if is_master?
      exchange_variants(:reload).destroy_all
      yield
      product.refresh_products_cache

    else
      OpenFoodNetwork::ProductsCache.variant_destroyed(self) do
        # Remove this association here instead of using dependent: :destroy because
        # dependent-destroy acts before this around_filter is called, so ProductsCache
        # has no way of knowing which exchanges the variant was a member of.
        exchange_variants(:reload).destroy_all

        # Destroy the variant
        yield
      end
    end
  end
end
