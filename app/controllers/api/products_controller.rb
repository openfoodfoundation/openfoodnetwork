require 'open_food_network/permissions'
require 'spree/core/product_duplicator'

module Api
  class ProductsController < Api::BaseController
    respond_to :json
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 15

    skip_authorization_check only: [:show, :bulk_products, :overridable]

    def show
      @product = find_product(params[:id])
      render json: @product, serializer: Api::Admin::ProductSerializer
    end

    def create
      authorize! :create, Spree::Product
      params[:product][:available_on] ||= Time.zone.now
      @product = Spree::Product.new(product_params)
      begin
        if @product.save
          render json: @product, serializer: Api::Admin::ProductSerializer, status: :created
        else
          invalid_resource!(@product)
        end
      rescue ActiveRecord::RecordNotUnique
        @product.permalink = nil
        retry
      end
    end

    def update
      authorize! :update, Spree::Product
      @product = find_product(params[:id])
      if @product.update(product_params)
        render json: @product, serializer: Api::Admin::ProductSerializer, status: :ok
      else
        invalid_resource!(@product)
      end
    end

    def destroy
      authorize! :delete, Spree::Product
      @product = find_product(params[:id])
      authorize! :delete, @product
      @product.destroy
      render json: @product, serializer: Api::Admin::ProductSerializer, status: :no_content
    end

    def bulk_products
      product_query = OpenFoodNetwork::Permissions.
        new(current_api_user).
        editable_products.
        merge(product_scope)

      if params[:import_date].present?
        product_query = product_query.
          imported_on(params[:import_date]).
          group_by_products_id
      end

      @products = product_query.
        ransack(query_params_with_defaults).
        result.
        page(params[:page] || DEFAULT_PAGE).
        per(params[:per_page] || DEFAULT_PER_PAGE)

      render_paged_products @products
    end

    def overridable
      producer_ids = OpenFoodNetwork::Permissions.new(current_api_user).
        variant_override_producers.by_name.select('enterprises.id')

      @products = paged_products_for_producers producer_ids

      render_paged_products @products, ::Api::Admin::ProductSimpleSerializer
    end

    # POST /api/products/:product_id/clone
    #
    def clone
      authorize! :create, Spree::Product
      original_product = find_product(params[:product_id])
      authorize! :update, original_product

      @product = original_product.duplicate

      render json: @product, serializer: Api::Admin::ProductSerializer, status: :created
    end

    private

    def find_product(id)
      product_scope.find_by!(permalink: id.to_s)
    rescue ActiveRecord::RecordNotFound
      product_scope.find(id)
    end

    def product_scope
      if current_api_user.has_spree_role?("admin") || current_api_user.enterprises.present?
        scope = Spree::Product
        if params[:show_deleted]
          scope = scope.with_deleted
        end
      else
        scope = Spree::Product.active
      end

      scope.includes(product_query_includes)
    end

    def product_query_includes
      [
        master: [:images],
        variants: [:default_price, :stock_locations, :stock_items, :variant_overrides,
                   { option_values: :option_type }]
      ]
    end

    def paged_products_for_producers(producer_ids)
      Spree::Product.where(nil).
        merge(product_scope).
        includes(variants: [:product, :default_price, :stock_items]).
        where(supplier_id: producer_ids).
        by_producer.by_name.
        ransack(params[:q]).result.
        page(params[:page]).per(params[:per_page])
    end

    def render_paged_products(products, product_serializer = ::Api::Admin::ProductSerializer)
      serializer = ActiveModel::ArraySerializer.new(
        products,
        each_serializer: product_serializer
      )

      render text: {
        products: serializer,
        # This line is used by the PagedFetcher JS service (inventory).
        pages: products.num_pages,
        # This hash is used by the BulkProducts JS service.
        pagination: pagination_data(products)
      }.to_json
    end

    def query_params_with_defaults
      (params[:q] || {}).reverse_merge(s: 'created_at desc')
    end

    def pagination_data(results)
      {
        results: results.total_count,
        pages: results.num_pages,
        page: (params[:page] || DEFAULT_PAGE).to_i,
        per_page: (params[:per_page] || DEFAULT_PER_PAGE).to_i
      }
    end

    def product_params
      params.require(:product).permit PermittedAttributes::Product.attributes
    end
  end
end
