require 'open_food_network/products_renderer'

RefreshProductsCacheJob = Struct.new(:distributor_id, :order_cycle_id) do
  def perform
    Rails.cache.write "products-json-#{distributor_id}-#{order_cycle_id}", products_json
  end


  private

  def products_json
    distributor = Enterprise.find distributor_id
    order_cycle = OrderCycle.find order_cycle_id
    OpenFoodNetwork::ProductsRenderer.new(distributor, order_cycle).products_json
  end
end
