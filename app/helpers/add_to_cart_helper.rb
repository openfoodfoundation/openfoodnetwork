module AddToCartHelper
  def product_out_of_stock
    !@product.has_stock? && !Spree::Config[:allow_backorders]
  end

  def product_incompatible_with_current_order(order, product)
    !DistributorChangeValidator.new(order).product_compatible_with_current_order(product)
  end

  def available_distributors_for(order, product)
    DistributorChangeValidator.new(order).available_distributors_for(product)
  end
end
