require 'open_food_network/products_renderer'

module OpenFoodNetwork
  class ProductsCacheIntegrityChecker
    def initialize(distributor, order_cycle)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def ok?
      diff.none?
    end

    def diff
      @diff ||= Diffy::Diff.new pretty(cached_json), pretty(rendered_json)
    end


    private

    def cached_json
      Rails.cache.read("products-json-#{@distributor.id}-#{@order_cycle.id}") || {}.to_json
    end

    def rendered_json
      OpenFoodNetwork::ProductsRenderer.new(@distributor, @order_cycle).products_json
    rescue OpenFoodNetwork::ProductsRenderer::NoProducts
      nil
    end

    def pretty(json)
      JSON.pretty_generate JSON.parse json
    end
  end
end
