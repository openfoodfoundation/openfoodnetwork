require 'open_food_network/scope_variant_to_hub'

# Previously Spree::OrderPopulator. Modified to work with max_quantity and variant overrides.

class CartService
  attr_accessor :order, :currency
  attr_reader :variants_h
  attr_reader :errors

  def initialize(order)
    @order = order
    @currency = order.currency
    @errors = ActiveModel::Errors.new(self)
  end

  def populate(from_hash, overwrite = false)
    @distributor, @order_cycle = distributor_and_order_cycle

    @order.with_lock do
      variants_data = read_variants from_hash
      attempt_cart_add_variants variants_data
      overwrite_variants variants_data if overwrite
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
      loaded_variant = loaded_variants[variant_data[:variant_id].to_i]

      if loaded_variant.deleted?
        remove_deleted_variant(loaded_variant)
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

  def remove_deleted_variant(variant)
    line_item_for_variant(variant).andand.destroy
  end

  def attempt_cart_add(variant, quantity, max_quantity = nil)
    quantity = quantity.to_i
    max_quantity = max_quantity.to_i if max_quantity
    return unless quantity > 0

    scoper.scope(variant)
    return unless valid_variant?(variant)

    cart_add(variant, quantity, max_quantity)
  end

  def cart_add(variant, quantity, max_quantity)
    quantity_to_add, max_quantity_to_add = quantities_to_add(variant, quantity, max_quantity)
    if quantity_to_add > 0
      @order.add_variant(variant, quantity_to_add, max_quantity_to_add, currency)
    else
      @order.remove_variant variant
    end
  end

  def quantities_to_add(variant, quantity, max_quantity)
    # If not enough stock is available, add as much as we can to the cart
    on_hand = variant.on_hand
    on_hand = [quantity, max_quantity].compact.max if variant.on_demand
    quantity_to_add = [quantity, on_hand].min
    max_quantity_to_add = max_quantity # max_quantity is not capped

    [quantity_to_add, max_quantity_to_add]
  end

  def overwrite_variants(variants)
    variants_removed(variants).each do |id|
      cart_remove(id)
    end
  end

  def scoper
    @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(@distributor)
  end

  def read_variants(data)
    @variants_h = read_variants_hash(data)
  end

  def read_variants_hash(data)
    variants_array = []
    (data[:variants] || []).each do |variant_id, quantity|
      if quantity.is_a?(ActionController::Parameters)
        variants_array.push({ variant_id: variant_id, quantity: quantity[:quantity], max_quantity: quantity[:max_quantity] })
      else
        variants_array.push({ variant_id: variant_id, quantity: quantity })
      end
    end
    variants_array
  end

  def cart_remove(variant_id)
    variant = Spree::Variant.find(variant_id)
    @order.remove_variant(variant)
  end

  def distributor_and_order_cycle
    [@order.distributor, @order.order_cycle]
  end

  # Returns true if the saved cart differs from what's in the posted data, otherwise false
  def varies_from_cart(variant_data, loaded_variant)
    li = line_item_for_variant loaded_variant

    li_added = li.nil? && (variant_data[:quantity].to_i > 0 || variant_data[:max_quantity].to_i > 0)
    li_quantity_changed = li.present? && li.quantity.to_i != variant_data[:quantity].to_i
    li_max_quantity_changed = li.present? && li.max_quantity.to_i != variant_data[:max_quantity].to_i

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
    return true if OrderCycleDistributedVariants.new(@order_cycle, @distributor).available_variants.include? variant

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
