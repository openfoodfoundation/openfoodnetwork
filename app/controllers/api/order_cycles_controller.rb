require 'open_food_network/products_renderer'

module Api
  class OrderCyclesController < BaseController
    include EnterprisesHelper
    respond_to :json

    skip_authorization_check

    def products
      products = OpenFoodNetwork::ProductsRenderer.new(current_distributor, current_order_cycle, params).products_json
      # products = ::ProductsFilterer.new(current_distributor, current_customer, products_json).call # TBD

      render json: products
    rescue OpenFoodNetwork::ProductsRenderer::NoProducts
      render status: :not_found, json: ''
    end

    def taxons
      taxons = Spree::Taxon.
        joins(:products).
        where(spree_products: { id: distributed_products(distributor, order_cycle, customer) }).
        select('DISTINCT spree_taxons.*')

      render json: ActiveModel::ArraySerializer.new(taxons, each_serializer: Api::TaxonSerializer)
    end

    def properties
      properties = Spree::Property.
        joins(:products).
        where(spree_products: { id: distributed_products(distributor, order_cycle, customer) }).
        select('DISTINCT spree_properties.*')

      render json: ActiveModel::ArraySerializer.new(
        properties, each_serializer: Api::PropertySerializer
      )
    end

    private

    def distributor
      Enterprise.find_by_id(params[:distributor])
    end

    def order_cycle
      OrderCycle.find_by_id(params[:id])
    end

    def customer
      @current_api_user.andand.customer_of(distributor) || nil
    end

    def distributed_products(distributor, order_cycle, customer)
      OrderCycleDistributedProducts.new(distributor, order_cycle, customer).products_relation
    end
  end
end
