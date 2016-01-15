require 'open_food_network/products_renderer'

RefreshProductsCacheJob = Struct.new(:distributor_id, :order_cycle_id) do
  def perform
    Rails.cache.write "products-json-#{distributor_id}-#{order_cycle_id}", products_json
  end


  private

  def products_json
    OpenFoodNetwork::ProductsRenderer.new(distributor_id, order_cycle_id).products_json
  end

end
