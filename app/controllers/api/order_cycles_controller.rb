module Api
  class OrderCyclesController < Api::BaseController
    include EnterprisesHelper
    include ApiActionCaching

    skip_authorization_check
    skip_before_action :authenticate_user, :ensure_api_key, only: [:taxons, :properties]

    caches_action :taxons, :properties,
                  expires_in: CacheService::FILTERS_EXPIRY,
                  cache_path: proc { |controller| controller.request.url }

    def products
      return render_no_products unless order_cycle.open?

      products = ProductsRenderer.new(
        distributor,
        order_cycle,
        customer,
        search_params
      ).products_json

      render plain: products, content_type: "application/json"
    rescue ProductsRenderer::NoProducts
      render_no_products
    end

    def taxons
      taxons = Spree::Taxon.
        joins(:products).
        where(spree_products: { id: distributed_products }).
        select('DISTINCT spree_taxons.*')

      render plain: ActiveModel::ArraySerializer.new(
        taxons, each_serializer: Api::TaxonSerializer
      ).to_json, content_type: "application/json"
    end

    def properties
      render plain: ActiveModel::ArraySerializer.new(
        product_properties | producer_properties, each_serializer: Api::PropertySerializer
      ).to_json, content_type: "application/json"
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
      [:name_or_meta_keywords_or_variants_display_as_or_variants_display_name_or_supplier_name_cont,
       :properties_id_or_supplier_properties_id_in_any,
       :primary_taxon_id_in_any]
    end

    def distributor
      @distributor ||= Enterprise.find_by(id: params[:distributor])
    end

    def order_cycle
      @order_cycle ||= OrderCycle.find_by(id: params[:id])
    end

    def customer
      @current_api_user.andand.customer_of(distributor) || nil
    end

    def distributed_products
      OrderCycleDistributedProducts.new(distributor, order_cycle, customer).products_relation
    end
  end
end
