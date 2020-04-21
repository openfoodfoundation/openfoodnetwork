module Api
  class OrderCyclesController < Api::BaseController
    include EnterprisesHelper
    respond_to :json
    skip_authorization_check

    FILTERS_EXPIRE = 30.seconds.freeze

    def products
      render_no_products unless order_cycle.open?

      products = ProductsRenderer.new(
        distributor,
        order_cycle,
        customer,
        search_params
      ).products_json

      render json: products
    rescue ProductsRenderer::NoProducts
      render_no_products
    end

    def taxons
      cache_key = "oc-taxons-#{order_cycle.id}-#{distributor.id}"

      taxons = CacheService.cache(cache_key, expires_in: FILTERS_EXPIRE) do
        Spree::Taxon.
          joins(:products).
          where(spree_products: { id: distributed_products }).
          select('DISTINCT spree_taxons.*')
      end

      render json: ActiveModel::ArraySerializer.new(taxons, each_serializer: Api::TaxonSerializer)
    end

    def properties
      cache_key = "oc-properties-#{order_cycle.id}-#{distributor.id}"

      properties = CacheService.cache(cache_key, expires_in: FILTERS_EXPIRE) do
        product_properties | producer_properties
      end

      render json: ActiveModel::ArraySerializer.new(
        properties, each_serializer: Api::PropertySerializer
      )
    end

    private

    def render_no_products
      render status: :not_found, json: ''
    end

    def product_properties
      Spree::Property.
        joins(:products).
        where(spree_products: { id: distributed_products }).
        select('DISTINCT spree_properties.*')
    end

    def producer_properties
      producers = Enterprise.
        joins(:supplied_products).
        where(spree_products: { id: distributed_products })

      Spree::Property.
        joins(:producer_properties).
        where(producer_properties: { producer_id: producers }).
        select('DISTINCT spree_properties.*')
    end

    def search_params
      permitted_search_params = params.slice :q, :page, :per_page

      if permitted_search_params.key? :q
        permitted_search_params[:q].slice!(*permitted_ransack_params)
      end

      permitted_search_params
    end

    def permitted_ransack_params
      [:name_or_meta_keywords_or_supplier_name_cont,
       :properties_id_or_supplier_properties_id_in_any,
       :primary_taxon_id_in_any]
    end

    def distributor
      @distributor ||= Enterprise.find_by_id(params[:distributor])
    end

    def order_cycle
      @order_cycle ||= OrderCycle.find_by_id(params[:id])
    end

    def customer
      @current_api_user.andand.customer_of(distributor) || nil
    end

    def distributed_products
      OrderCycleDistributedProducts.new(distributor, order_cycle, customer).products_relation
    end
  end
end
