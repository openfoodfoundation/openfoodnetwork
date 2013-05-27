module AddToCartHelper
  def product_out_of_stock
    !@product.has_stock? && !Spree::Config[:allow_backorders]
  end

  def product_incompatible_with_current_order(order, product)
    !order.nil? && !DistributorChangeValidator.new(order).can_change_distributor? && !Enterprise.distributing_product(product).include?(order.distributor)
  end

  def available_distributors_for(order, product)
    distributors = Enterprise.distributing_product(product)

    if order && order.distributor
      distributors = DistributorChangeValidator.new(order).available_distributors(distributors)
    end

    distributors
  end
end
