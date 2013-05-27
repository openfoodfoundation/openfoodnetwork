module AddToCartHelper
  def product_out_of_stock
    !@product.has_stock? && !Spree::Config[:allow_backorders]
  end

  def product_incompatible_with_current_order(order, product)
    order.present? && available_distributors_for(order, product).empty?
  end

  def available_distributors_for(order, product)
    distributors = Enterprise.distributing_product(product)

    if order && order.distributor
      distributors = DistributorChangeValidator.new(order).available_distributors(distributors)
    end

    distributors
  end
end
