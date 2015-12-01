require 'open_food_network/enterprise_fee_calculator'
require 'open_food_network/variant_and_line_item_naming'

Spree::Variant.class_eval do
  # Remove method From Spree, so method from the naming module is used instead
  # This file may be double-loaded in delayed job environment, so we check before
  # removing the Spree method to prevent error.
  remove_method :options_text if instance_methods(false).include? :options_text
  include OpenFoodNetwork::VariantAndLineItemNaming


  has_many :exchange_variants, dependent: :destroy
  has_many :exchanges, through: :exchange_variants
  has_many :variant_overrides

  attr_accessible :unit_value, :unit_description, :images_attributes, :display_as, :display_name
  accepts_nested_attributes_for :images

  validates_presence_of :unit_value,
    if: -> v { %w(weight volume).include? v.product.andand.variant_unit }

  validates_presence_of :unit_description,
    if: -> v { v.product.andand.variant_unit.present? && v.unit_value.nil? }

  before_validation :update_weight_from_unit_value, if: -> v { v.product.present? }
  after_save :update_units

  scope :with_order_cycles_inner, joins(exchanges: :order_cycle)
  scope :with_order_cycles_outer, joins('LEFT OUTER JOIN exchange_variants AS o_exchange_variants ON (o_exchange_variants.variant_id = spree_variants.id)').
                                  joins('LEFT OUTER JOIN exchanges AS o_exchanges ON (o_exchanges.id = o_exchange_variants.exchange_id)').
                                  joins('LEFT OUTER JOIN order_cycles AS o_order_cycles ON (o_order_cycles.id = o_exchanges.order_cycle_id)')

  scope :not_deleted, where(deleted_at: nil)
  scope :in_stock, where('spree_variants.count_on_hand > 0 OR spree_variants.on_demand=?', true)
  scope :in_distributor, lambda { |distributor|
    with_order_cycles_outer.
    where('o_exchanges.incoming = ? AND o_exchanges.receiver_id = ?', false, distributor).
    select('DISTINCT spree_variants.*')
  }

  scope :in_order_cycle, lambda { |order_cycle|
    with_order_cycles_inner.
    merge(Exchange.outgoing).
    where('order_cycles.id = ?', order_cycle).
    select('DISTINCT spree_variants.*')
  }

  scope :for_distribution, lambda { |order_cycle, distributor|
    where('spree_variants.id IN (?)', order_cycle.variants_distributed_by(distributor))
  }


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

  # TODO: Should this be moved into VariantAndLineItemNaming?
  def product_and_variant_name
    name = product.name

    name += " - #{name_to_display}" if name_to_display != product.name
    name += " (#{options_text})" if options_text

    name
  end

  def delete
    if product.variants == [self] # Only variant left on product
      errors.add :product, "must have at least one variant"
      false
    else
      transaction do
        self.update_column(:deleted_at, Time.now)
        ExchangeVariant.where(variant_id: self).destroy_all
        self
      end
    end
  end

  private

  def update_weight_from_unit_value
    self.weight = weight_from_unit_value if self.product.variant_unit == 'weight' && unit_value.present?
  end
end
