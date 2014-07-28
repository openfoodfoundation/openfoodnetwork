Spree::OrderPopulator.class_eval do
  def populate(from_hash, overwrite = false)
    @distributor, @order_cycle = distributor_and_order_cycle
    # Refactor: We may not need this validation - we can't change distribution here, so
    # this validation probably can't fail
    if !distribution_can_supply_products_in_cart(@distributor, @order_cycle)
      errors.add(:base, "That distributor or order cycle can't supply all the products in your cart. Please choose another.")
    end

    if valid? 
      @order.with_lock do
        @order.empty! if overwrite

        from_hash[:products].each do |product_id, variant_id|
          attempt_cart_add(variant_id, from_hash[:quantity])
        end if from_hash[:products]

        from_hash[:variants].each do |variant_id, args|
          attempt_cart_add(variant_id, args[:quantity], args[:max_quantity])
        end if from_hash[:variants]
      end
    end

    valid?
  end

  def attempt_cart_add(variant_id, quantity, max_quantity = nil)
    quantity = quantity.to_i
    variant = Spree::Variant.find(variant_id)
    if quantity > 0
      if check_stock_levels(variant, quantity) &&
          check_order_cycle_provided_for(variant) &&
          check_variant_available_under_distribution(variant)
        @order.add_variant(variant, quantity, max_quantity, currency)
      end
    end
  end


  private

  def distributor_and_order_cycle
    [@order.distributor, @order.order_cycle]
  end

  def distribution_can_supply_products_in_cart(distributor, order_cycle)
    DistributionChangeValidator.new(@order).can_change_to_distribution?(distributor, order_cycle)
  end

  def check_order_cycle_provided_for(variant)
    order_cycle_provided = (!order_cycle_required_for(variant) || @order_cycle.present?)
    errors.add(:base, "Please choose an order cycle for this order.") unless order_cycle_provided
    order_cycle_provided
  end

  def check_variant_available_under_distribution(variant)
    if DistributionChangeValidator.new(@order).variants_available_for_distribution(@distributor, @order_cycle).include? variant
      return true
    else
      errors.add(:base, "That product is not available from the chosen distributor or order cycle.")
      return false
    end
  end

  def order_cycle_required_for(variant)
    variant.product.product_distributions.empty?
  end
end
