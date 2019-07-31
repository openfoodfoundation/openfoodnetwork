require 'open_food_network/permissions'

module Spree
  module Api
    class ProductsController < Spree::Api::BaseController
      respond_to :json

      def show
        @product = find_product(params[:id])
        render json: @product, serializer: ::Api::Admin::ProductSerializer
      end

      def create
        authorize! :create, Product
        params[:product][:available_on] ||= Time.zone.now
        @product = Product.new(params[:product])
        begin
          if @product.save
            render json: @product, serializer: ::Api::Admin::ProductSerializer, status: 201
          else
            invalid_resource!(@product)
          end
        rescue ActiveRecord::RecordNotUnique
          @product.permalink = nil
          retry
        end
      end

      def update
        authorize! :update, Product
        @product = find_product(params[:id])
        if @product.update_attributes(params[:product])
          render json: @product, serializer: ::Api::Admin::ProductSerializer, status: 200
        else
          invalid_resource!(@product)
        end
      end

      def destroy
        authorize! :delete, Product
        @product = find_product(params[:id])
        @product.update_attribute(:deleted_at, Time.zone.now)
        @product.variants_including_master.update_all(deleted_at: Time.zone.now)
        render json: @product, serializer: ::Api::Admin::ProductSerializer, status: 204
      end

      # TODO: This should be named 'managed'. Is the action above used? Maybe we should remove it.
      def bulk_products
        @products = OpenFoodNetwork::Permissions.new(current_api_user).editable_products.
          merge(product_scope).
          order('created_at DESC').
          ransack(params[:q]).result.
          page(params[:page]).per(params[:per_page])

        render_paged_products @products
      end

      def overridable
        producers = OpenFoodNetwork::Permissions.new(current_api_user).
          variant_override_producers.by_name

        @products = paged_products_for_producers producers

        render_paged_products @products
      end

      def soft_delete
        authorize! :delete, Spree::Product
        @product = find_product(params[:product_id])
        authorize! :delete, @product
        @product.destroy
        render json: @product, serializer: ::Api::Admin::ProductSerializer, status: 204
      end

      # POST /api/products/:product_id/clone
      #
      def clone
        authorize! :create, Spree::Product
        original_product = find_product(params[:product_id])
        authorize! :update, original_product

        @product = original_product.duplicate

        render json: @product, serializer: ::Api::Admin::ProductSerializer, status: 201
      end

      private

      # Copied and modified from Spree::Api::BaseController to allow
      # enterprise users to access inactive products
      def product_scope
        # This line modified
        if current_api_user.has_spree_role?("admin") || current_api_user.enterprises.present?
          scope = Spree::Product
          if params[:show_deleted]
            scope = scope.with_deleted
          end
        else
          scope = Spree::Product.active
        end

        scope.includes(:master)
      end

      def paged_products_for_producers(producers)
        Spree::Product.scoped.
          merge(product_scope).
          where(supplier_id: producers).
          by_producer.by_name.
          ransack(params[:q]).result.
          page(params[:page]).per(params[:per_page])
      end

      def render_paged_products(products)
        serializer = ActiveModel::ArraySerializer.new(
          products,
          each_serializer: ::Api::Admin::ProductSerializer
        )

        render text: { products: serializer, pages: products.num_pages }.to_json
      end
    end
  end
end
