require 'open_food_network/products_renderer'

# Wrapper for ProductsRenderer that caches the JSON output.
# ProductsRenderer::NoProducts is represented in the cache as nil,
# but re-raised to provide the same interface as ProductsRenderer.

module OpenFoodNetwork
  class CachedProductsRenderer
    class NoProducts < Exception; end

    def initialize(distributor, order_cycle)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def products_json
      raise NoProducts.new("No Products") if @distributor.nil? || @order_cycle.nil?

      products_json = cached_products_json

      raise NoProducts.new("No Products") if products_json.nil?

      products_json
    end


    private

    def log_warning
      if Rails.env.production? || Rails.env.staging?
        Bugsnag.notify RuntimeError.new("Live server MISS on products cache for distributor: #{@distributor.id}, order cycle: #{@order_cycle.id}")
      end
    end

    def cached_products_json
      if Rails.env.production? || Rails.env.staging?
        Rails.cache.fetch("products-json-#{@distributor.id}-#{@order_cycle.id}") do
          log_warning

          begin
            uncached_products_json
          rescue ProductsRenderer::NoProducts
            nil
          end
        end
      else
        uncached_products_json
      end
    end

    def uncached_products_json
      ProductsRenderer.new(@distributor, @order_cycle).products_json
    end
  end
end
