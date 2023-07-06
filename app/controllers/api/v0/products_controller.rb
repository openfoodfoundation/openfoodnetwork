# frozen_string_literal: true

require 'open_food_network/permissions'
require 'spree/core/product_duplicator'

module Api
  module V0
    class ProductsController < Api::V0::BaseController
      include PaginationData
      respond_to :json
      DEFAULT_PER_PAGE = 15

      skip_authorization_check only: [:show, :bulk_products, :overridable]

      def show
        @product = find_product(params[:id])
        render json: @product, serializer: Api::Admin::ProductSerializer
      end

      def create
        authorize! :create, Spree::Product
        @product = Spree::Product.new(product_params)

        if @product.save
          render json: @product, serializer: Api::Admin::ProductSerializer, status: :created
        else
          invalid_resource!(@product)
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
          result

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
          image: { attachment_attachment: :blob },
          variants: [:default_price, :stock_locations, :stock_items, :variant_overrides]
        ]
      end

      def paged_products_for_producers(producer_ids)
        Spree::Product.where(nil).
          merge(product_scope).
          includes(variants: [:product, :default_price, :stock_items]).
          where(supplier_id: producer_ids).
          by_producer.by_name.
          ransack(params[:q]).result
      end

      def render_paged_products(products, product_serializer = ::Api::Admin::ProductSerializer)
        @pagy, products = pagy(products, items: params[:per_page] || DEFAULT_PER_PAGE)

        serialized_products = ActiveModel::ArraySerializer.new(
          products,
          each_serializer: product_serializer
        )

        render json: {
          products: serialized_products,
          pagination: pagination_data
        }
      end

      def query_params_with_defaults
        (params[:q] || {}).reverse_merge(s: 'created_at desc')
      end

      def product_params
        @product_params ||=
          params.permit(product: PermittedAttributes::Product.attributes)[:product].to_h
      end
    end
  end
end
