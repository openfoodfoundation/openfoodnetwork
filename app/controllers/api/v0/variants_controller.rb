# frozen_string_literal: true

module Api
  module V0
    class VariantsController < Api::V0::BaseController
      respond_to :json

      skip_authorization_check only: [:index, :show]
      before_action :product

      def index
        @variants = scope.ransack(params[:q]).result
        render json: @variants, each_serializer: Api::VariantSerializer
      end

      def show
        @variant = scope.find(params[:id])
        render json: @variant, serializer: Api::VariantSerializer
      end

      def create
        authorize! :create, Spree::Variant
        @variant = scope.new(variant_params)
        if @variant.save
          render json: @variant, serializer: Api::VariantSerializer, status: :created
        else
          invalid_resource!(@variant)
        end
      end

      def update
        authorize! :update, Spree::Variant
        @variant = scope.find(params[:id])
        if @variant.update(variant_params)
          render json: @variant, serializer: Api::VariantSerializer, status: :ok
        else
          invalid_resource!(@product)
        end
      end

      def destroy
        authorize! :delete, Spree::Variant
        @variant = scope.find(params[:id])
        authorize! :delete, @variant

        VariantDeleter.new.delete(@variant)
        render json: @variant, serializer: Api::VariantSerializer, status: :no_content
      end

      private

      def product
        @product ||= Spree::Product.find(params[:product_id]) if params[:product_id]
      end

      def scope
        if @product
          variants = if current_api_user.has_spree_role?("admin") || params[:show_deleted]
                       @product.variants.with_deleted
                     else
                       @product.variants
                     end
        else
          variants = Spree::Variant.where(nil)
          if current_api_user.has_spree_role?("admin")
            unless params[:show_deleted]
              variants = Spree::Variant.active
            end
          else
            variants = variants.active
          end
        end
        variants
      end

      def variant_params
        params.require(:variant).permit(PermittedAttributes::Variant.attributes)
      end
    end
  end
end
