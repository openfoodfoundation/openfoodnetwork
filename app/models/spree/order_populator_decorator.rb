Spree::OrderPopulator.class_eval do
  def populate_with_distribution_validation(from_hash)
    @distributor = from_hash[:distributor_id].present? ?
      Enterprise.is_distributor.find(from_hash[:distributor_id]) : nil
    @order_cycle = from_hash[:order_cycle_id].present? ?
                     OrderCycle.find(from_hash[:order_cycle_id]) : nil

    if @distributor && !DistributionChangeValidator.new(@order).can_change_to_distributor?(@distributor)
      errors.add(:base, "That distributor can't supply all the products in your cart. Please choose another.")
    end

    populate_without_distribution_validation(from_hash) if valid?

    # Set order distributor and order cycle
    if valid?
      # Using @order.reload or not performing any reload causes totals fields (ie. item_total)
      # to be set to zero
      @order = Spree::Order.find @order.id

      @order.set_distributor! @distributor
      @order.set_order_cycle! @order_cycle if @order_cycle
    end

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
          check_variant_available_under_distributor(variant)

        @order.add_variant(variant, quantity, currency)
      end
    end
  end

  def check_distribution_provided_for(variant)
    order_cycle_required = order_cycle_required_for(variant)
    distribution_provided =
      @distributor.present? && (!order_cycle_required || @order_cycle.present?)

    unless distribution_provided
      if order_cycle_required
        errors.add(:base, "Please choose a distributor and order cycle for this order.")
      else
        errors.add(:base, "Please choose a distributor for this order.")
      end
    end

    distribution_provided
  end

  def check_variant_available_under_distributor(variant)
    if Enterprise.distributing_product(variant.product).include? @distributor
      return true
    else
      errors.add(:base, "That product is not available from the chosen distributor.")
      return false
    end
  end

  def order_cycle_required_for(variant)
    variant.product.product_distributions.empty?
  end

end
