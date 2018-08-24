require 'open_food_network/scope_variant_to_hub'

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
    # Refactor: We may not need this validation - we can't change distribution here, so
    # this validation probably can't fail
    if !distribution_can_supply_products_in_cart(@distributor, @order_cycle)
      errors.add(:base, I18n.t(:spree_order_populator_error))
      return false
    end

    @order.with_lock do
      variants = read_variants from_hash
      attempt_cart_add_variants variants
      overwrite_variants variants unless !overwrite
    end
    valid?
  end

  def attempt_cart_add_variants(variants)
    variants.each do |v|
      if varies_from_cart(v)
        attempt_cart_add(v[:variant_id], v[:quantity], v[:max_quantity])
      end
    end
  end

  def attempt_cart_add(variant_id, quantity, max_quantity = nil)
    quantity = quantity.to_i
    max_quantity = max_quantity.to_i if max_quantity
    variant = Spree::Variant.find(variant_id)
    OpenFoodNetwork::ScopeVariantToHub.new(@distributor).scope(variant)

    return unless quantity > 0 && valid_variant?(variant)

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
    on_hand = [quantity, max_quantity].compact.max if Spree::Config.allow_backorders
    quantity_to_add = [quantity, on_hand].min
    max_quantity_to_add = max_quantity # max_quantity is not capped

    [quantity_to_add, max_quantity_to_add]
  end

  def overwrite_variants(variants)
    variants_removed(variants).each do |id|
      cart_remove(id)
    end
  end

  private

  def read_variants(data)
    @variants_h = read_products_hash(data) +
                  read_variants_hash(data)
  end

  def read_products_hash(data)
    (data[:products] || []).map do |_product_id, variant_id|
      { variant_id: variant_id, quantity: data[:quantity] }
    end
  end

  def read_variants_hash(data)
    (data[:variants] || []).map do |variant_id, quantity|
      if quantity.is_a?(Hash)
        { variant_id: variant_id, quantity: quantity[:quantity], max_quantity: quantity[:max_quantity] }
      else
        { variant_id: variant_id, quantity: quantity }
      end
    end
  end

  def valid?
    errors.empty?
  end

  def cart_remove(variant_id)
    variant = Spree::Variant.find(variant_id)
    @order.remove_variant(variant)
  end

  def distributor_and_order_cycle
    [@order.distributor, @order.order_cycle]
  end

  def distribution_can_supply_products_in_cart(distributor, order_cycle)
    DistributionChangeValidator.new(@order).can_change_to_distribution?(distributor, order_cycle)
  end

  def varies_from_cart(variant_data)
    li = line_item_for_variant_id variant_data[:variant_id]

    li_added = li.nil? && (variant_data[:quantity].to_i > 0 || variant_data[:max_quantity].to_i > 0)
    li_quantity_changed     = li.present? && li.quantity.to_i     != variant_data[:quantity].to_i
    li_max_quantity_changed = li.present? && li.max_quantity.to_i != variant_data[:max_quantity].to_i

    li_added || li_quantity_changed || li_max_quantity_changed
  end

  def variants_removed(variants_data)
    variant_ids_given = variants_data.map { |data| data[:variant_id].to_i }

    (variant_ids_in_cart - variant_ids_given).uniq
  end

  def valid_variant?(variant)
    check_order_cycle_provided_for(variant) && check_variant_available_under_distribution(variant)
  end

  def check_order_cycle_provided_for(variant)
    order_cycle_provided = (!order_cycle_required_for(variant) || @order_cycle.present?)
    errors.add(:base, "Please choose an order cycle for this order.") unless order_cycle_provided
    order_cycle_provided
  end

  def check_variant_available_under_distribution(variant)
    return true if DistributionChangeValidator.new(@order).variants_available_for_distribution(@distributor, @order_cycle).include? variant

    errors.add(:base, I18n.t(:spree_order_populator_availability_error))
    false
  end

  def order_cycle_required_for(variant)
    variant.product.product_distributions.empty?
  end

  def line_item_for_variant_id(variant_id)
    order.find_line_item_by_variant Spree::Variant.find(variant_id)
  end

  def variant_ids_in_cart
    @order.line_items.pluck :variant_id
  end
end
