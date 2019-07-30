module Spree
  module Api
    class VariantsController < ::Api::BaseController
      respond_to :json

      skip_authorization_check only: [:index, :show]
      before_filter :product

      def index
        @variants = scope.includes(:option_values).ransack(params[:q]).result
        render json: @variants, each_serializer: ::Api::VariantSerializer
      end

      def show
        @variant = scope.includes(:option_values).find(params[:id])
        render json: @variant, serializer: ::Api::VariantSerializer
      end

      def create
        authorize! :create, Variant
        @variant = scope.new(params[:variant])
        if @variant.save
          render json: @variant, serializer: ::Api::VariantSerializer, status: 201
        else
          invalid_resource!(@variant)
        end
      end

      def update
        authorize! :update, Variant
        @variant = scope.find(params[:id])
        if @variant.update_attributes(params[:variant])
          render json: @variant, serializer: ::Api::VariantSerializer, status: 200
        else
          invalid_resource!(@product)
        end
      end

      def soft_delete
        @variant = scope.find(params[:variant_id])
        authorize! :delete, @variant

        VariantDeleter.new.delete(@variant)
        render json: @variant, serializer: ::Api::VariantSerializer, status: 204
      end

      def destroy
        authorize! :delete, Variant
        @variant = scope.find(params[:id])
        @variant.destroy
        render json: @variant, serializer: ::Api::VariantSerializer, status: 204
      end

      private

      def product
        @product ||= Spree::Product.find_by_permalink(params[:product_id]) if params[:product_id]
      end

      def scope
        if @product
          unless current_api_user.has_spree_role?("admin") || params[:show_deleted]
            variants = @product.variants_including_master
          else
            variants = @product.variants_including_master.with_deleted
          end
        else
          variants = Variant.scoped
          if current_api_user.has_spree_role?("admin")
            unless params[:show_deleted]
              variants = Variant.active
            end
          else
            variants = variants.active
          end
        end
        variants
      end
    end
  end
end
