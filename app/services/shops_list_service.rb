# frozen_string_literal: true

class ShopsListService
  def open_shops
    shops_list.ready_for_checkout.all
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
      .includes(:distributed_product_properties, :distributed_producer_properties)
  end
end
