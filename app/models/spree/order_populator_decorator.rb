Spree::OrderPopulator.class_eval do
  def populate_with_distribution_validation(from_hash)
    @distributor, @order_cycle = orig_distributor_and_order_cycle

    # Refactor: We may not need this validation - we can't change distribution here, so
    # this validation probably can't fail
    if !distribution_can_supply_products_in_cart(@distributor, @order_cycle)
      errors.add(:base, "That distributor or order cycle can't supply all the products in your cart. Please choose another.")
    end

    populate_without_distribution_validation(from_hash) if valid?

    valid?
  end
  alias_method_chain :populate, :distribution_validation


  # Copied from Spree::OrderPopulator, with additional validations added
  def attempt_cart_add(variant_id, quantity)
    quantity = quantity.to_i
    variant = Spree::Variant.find(variant_id)
    if quantity > 0
      if check_stock_levels(variant, quantity) &&
          check_distribution_provided_for(variant) &&
          check_variant_available_under_distribution(variant)

        @order.add_variant(variant, quantity, currency)
      end
    end
  end


  private

  def orig_distributor_and_order_cycle
    [@order.distributor, @order.order_cycle]
  end


  def load_distributor_and_order_cycle(from_hash)
    distributor = from_hash[:distributor_id].present? ?
                    Enterprise.is_distributor.find(from_hash[:distributor_id]) : nil
    order_cycle = from_hash[:order_cycle_id].present? ?
                     OrderCycle.find(from_hash[:order_cycle_id]) : nil

    [distributor, order_cycle]
  end

  def set_cart_distributor_and_order_cycle(distributor, order_cycle)
    # Using @order.reload or not performing any reload causes totals fields (ie. item_total)
    # to be set to zero
    @order = Spree::Order.find @order.id

    @order.set_distribution! distributor, order_cycle
  end

  def distribution_can_supply_products_in_cart(distributor, order_cycle)
    DistributionChangeValidator.new(@order).can_change_to_distribution?(distributor, order_cycle)
  end

  def check_distribution_provided_for(variant)
    distribution_provided = distribution_provided_for variant

    unless distribution_provided
      if order_cycle_required_for variant
        errors.add(:base, "Please choose a distributor and order cycle for this order.")
      else
        errors.add(:base, "Please choose a distributor for this order.")
      end
    end

    distribution_provided
  end

  def check_variant_available_under_distribution(variant)
    if DistributionChangeValidator.new(@order).variants_available_for_distribution(@distributor, @order_cycle).include? variant
      return true
    else
      errors.add(:base, "That product is not available from the chosen distributor or order cycle.")
      return false
    end
  end

  def distribution_provided_for(variant)
    @distributor.present? && (!order_cycle_required_for(variant) || @order_cycle.present?)
  end

  def order_cycle_required_for(variant)
    variant.product.product_distributions.empty?
  end
end
