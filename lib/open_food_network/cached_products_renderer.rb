require 'open_food_network/products_renderer'

# Wrapper for ProductsRenderer that caches the JSON output.
# ProductsRenderer::NoProducts is represented in the cache as nil,
# but re-raised to provide the same interface as ProductsRenderer.

module OpenFoodNetwork
  class CachedProductsRenderer
    def initialize(distributor, order_cycle)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def products_json
      products_json = Rails.cache.fetch("products-json-#{@distributor.id}-#{@order_cycle.id}") do
        begin
          uncached_products_json
        rescue ProductsRenderer::NoProducts
          nil
        end
      end

      raise ProductsRenderer::NoProducts.new if products_json.nil?

      products_json
    end


    private

    def uncached_products_json
      ProductsRenderer.new(@distributor, @order_cycle).products_json
    end
  end
end
