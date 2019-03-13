require 'open_food_network/products_renderer'

RefreshProductsCacheJob = Struct.new(:distributor_id, :order_cycle_id) do
  def perform
    Rails.cache.write(key, products_json)
  end

  private

  def key
    "products-json-#{distributor_id}-#{order_cycle_id}"
  end

  def products_json
    distributor = Enterprise.find distributor_id
    order_cycle = OrderCycle.find order_cycle_id
    OpenFoodNetwork::ProductsRenderer.new(distributor, order_cycle).products_json
  end
end
