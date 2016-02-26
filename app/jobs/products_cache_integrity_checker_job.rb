require 'open_food_network/products_renderer'

ProductsCacheIntegrityCheckerJob = Struct.new(:distributor_id, :order_cycle_id) do
  def perform
    if diff.any?
      Bugsnag.notify RuntimeError.new("Products JSON differs from cached version for distributor: #{distributor_id}, order cycle: #{order_cycle_id}"), diff: diff.to_s(:text)
    end
  end


  private

  def diff
    @diff ||= Diffy::Diff.new pretty(cached_json), pretty(rendered_json)
  end

  def pretty(json)
    JSON.pretty_generate JSON.parse json
  end

  def cached_json
    Rails.cache.read("products-json-#{distributor_id}-#{order_cycle_id}") || {}.to_json
  end

  def rendered_json
    OpenFoodNetwork::ProductsRenderer.new(distributor, order_cycle).products_json
  rescue OpenFoodNetwork::ProductsRenderer::NoProducts
    nil
  end

  def distributor
    Enterprise.find distributor_id
  end

  def order_cycle
    OrderCycle.find order_cycle_id
  end
end
