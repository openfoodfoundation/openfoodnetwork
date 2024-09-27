# frozen_string_literal: true

class ShopsListService
  # shops that are ready for checkout, and have an order cycle that is currently open
  def open_shops
    shops_list.
      ready_for_checkout.
      distributors_with_active_order_cycles
  end

  # shops that are either not ready for checkout, or don't have an open order cycle; the inverse of
  # #open_shops
  def closed_shops
    shops_list.where.not(id: open_shops.reselect("enterprises.id"))
  end

  private

  def shops_list
    Enterprise
      .activated
      .visible
      .is_distributor
      .includes(address: [:state, :country])
      .includes(:properties)
      .includes(supplied_products: :properties)
      .with_attached_promo_image
      .with_attached_logo
  end
end
