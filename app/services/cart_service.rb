# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

# Previously Spree::OrderPopulator. Modified to work with max_quantity and variant overrides.

class CartService
  attr_accessor :order
  attr_reader :errors

  def initialize(order)
    @order = order
    @errors = ActiveModel::Errors.new(self)
  end

  def populate(from_hash)
    @distributor, @order_cycle = distributor_and_order_cycle

    variants_data = read_variants_hash(from_hash)

    @order.with_lock do
      attempt_cart_add_variants variants_data
      overwrite_variants variants_data
    end
    valid?
  end

  def valid?
    errors.empty?
  end

  private

  def attempt_cart_add_variants(variants_data)
    loaded_variants = indexed_variants(variants_data)

    variants_data.each do |variant_data|
      loaded_variant = loaded_variants[variant_data[:variant_id]]

      if loaded_variant.deleted? || !variant_data[:quantity].positive?
        cart_remove(loaded_variant)
        next
      end

      next unless varies_from_cart(variant_data, loaded_variant)

      attempt_cart_add(loaded_variant, variant_data[:quantity], variant_data[:max_quantity])
    end
  end

  def indexed_variants(variants_data)
    @indexed_variants ||= begin
      variant_ids_in_data = variants_data.map{ |v| v[:variant_id] }

      Spree::Variant.with_deleted.where(id: variant_ids_in_data).
        includes(:default_price, :stock_items, :product).
        index_by(&:id)
    end
  end

  def attempt_cart_add(variant, quantity, max_quantity = nil)
    scoper.scope(variant)
    return unless valid_variant?(variant)

    cart_add(variant, quantity, max_quantity)
  end

  def cart_add(variant, quantity, max_quantity)
    attributes = final_quantities(variant, quantity, max_quantity)

    if attributes[:quantity].positive?
      @order.contents.update_or_create(variant, attributes)
    else
      cart_remove(variant)
    end
  end

  def cart_remove(variant)
    order.contents.remove(variant)
  rescue ActiveRecord::RecordNotFound
    # Nothing to remove; no line items for this variant were found.
  end

  def final_quantities(variant, quantity, max_quantity)
    # If not enough stock is available, add as much as we can to the cart
    on_hand = variant.on_hand
    on_hand = [quantity, max_quantity].compact.max if variant.on_demand
    final_quantity = [quantity, on_hand].min
    final_max_quantity = max_quantity # max_quantity is not capped

    { quantity: final_quantity, max_quantity: final_max_quantity }
  end

  def overwrite_variants(variants)
    variants_removed(variants).each do |variant_id|
      variant = Spree::Variant.with_deleted.find(variant_id)
      cart_remove(variant)
    end
  end

  def scoper
    @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(@distributor)
  end

  def read_variants_hash(data)
    variants_array = []
    (data[:variants] || []).each do |variant_id, quantity|
      if quantity.is_a?(ActionController::Parameters)
        variants_array.push({
                              variant_id: variant_id.to_i,
                              quantity: quantity[:quantity].to_i,
                              max_quantity: quantity[:max_quantity].to_i
                            })
      else
        variants_array.push({
                              variant_id: variant_id.to_i,
                              quantity: quantity.to_i
                            })
      end
    end
    variants_array
  end

  def distributor_and_order_cycle
    [@order.distributor, @order.order_cycle]
  end

  # Returns true if the saved cart differs from what's in the posted data, otherwise false
  def varies_from_cart(variant_data, loaded_variant)
    li = line_item_for_variant loaded_variant

    li_added = li.nil? && (variant_data[:quantity].to_i > 0 || variant_data[:max_quantity].to_i > 0)
    li_quantity_changed = li.present? && li.quantity != variant_data[:quantity].to_i
    li_max_quantity_changed = li.present? &&
                              li.max_quantity.to_i != variant_data[:max_quantity].to_i

    li_added || li_quantity_changed || li_max_quantity_changed
  end

  def variants_removed(variants_data)
    variant_ids_given = variants_data.map { |data| data[:variant_id].to_i }

    (variant_ids_in_cart - variant_ids_given).uniq
  end

  def valid_variant?(variant)
    check_order_cycle_provided && check_variant_available_under_distribution(variant)
  end

  def check_order_cycle_provided
    order_cycle_provided = @order_cycle.present?
    errors.add(:base, I18n.t(:spree_order_cycle_error)) unless order_cycle_provided
    order_cycle_provided
  end

  def check_variant_available_under_distribution(variant)
    return true if OrderCycleDistributedVariants.new(@order_cycle, @distributor)
      .available_variants.include? variant

    errors.add(:base, I18n.t(:spree_order_populator_availability_error))
    false
  end

  def line_item_for_variant(variant)
    order.find_line_item_by_variant variant
  end

  def variant_ids_in_cart
    @order.line_items.pluck :variant_id
  end
end
