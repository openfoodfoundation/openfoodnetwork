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
        @product = product_finder.find_product
        render json: @product, serializer: Api::Admin::ProductSerializer
      end

      def create
        authorize! :create, Spree::Product
        @product = Spree::Product.new(product_params)

        if @product.save(context: :create_and_create_standard_variant)
          render json: @product, serializer: Api::Admin::ProductSerializer, status: :created
        else
          invalid_resource!(@product)
        end
      end

      def update
        authorize! :update, Spree::Product
        @product = product_finder.find_product
        if @product.update(product_params)
          render json: @product, serializer: Api::Admin::ProductSerializer, status: :ok
        else
          invalid_resource!(@product)
        end
      end

      def overridable
        @products = product_finder.products_for_producers

        render_paged_products @products, ::Api::Admin::ProductSimpleSerializer
      end

      private

      def product_finder
        ProductScopeQuery.new(current_api_user, params)
      end

      def render_paged_products(products, product_serializer = ::Api::Admin::ProductSerializer)
        @pagy, products = pagy(products, limit: params[:per_page] || DEFAULT_PER_PAGE)

        serialized_products = ActiveModel::ArraySerializer.new(
          products,
          each_serializer: product_serializer
        )

        render json: {
          products: serialized_products,
          pagination: pagination_data
        }
      end

      def product_params
        @product_params ||=
          params.permit(product: PermittedAttributes::Product.attributes)[:product].to_h
      end
    end
  end
end
