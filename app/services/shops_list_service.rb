# frozen_string_literal: true

class ShopsListService
  def open_shops
    shops_list.
      ready_for_checkout.
      distributors_with_active_order_cycles.
      all
  end

  def closed_shops
    shops_list.not_ready_for_checkout.all
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
