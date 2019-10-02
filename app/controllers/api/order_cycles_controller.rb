module Api
  class OrderCyclesController < BaseController
    respond_to :json

    def products
      products = OpenFoodNetwork::ProductsRenderer.new(current_distributor, current_order_cycle, params).products_json
      # products = ::ProductsFilterer.new(current_distributor, current_customer, products_json).call # TBD

      render json: products
    rescue OpenFoodNetwork::ProductsRenderer::NoProducts
      render status: :not_found, json: ''
    end
  end
end
