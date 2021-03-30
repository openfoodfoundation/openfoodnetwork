# frozen_string_literal: true

module Api
  module V0
    class ProductImagesController < Api::V0::BaseController
      respond_to :json

      def update_product_image
        @product = Spree::Product.find(params[:product_id])
        authorize! :update, @product

        if @product.images.first.nil?
          @image = Spree::Image.create(
            attachment: params[:file],
            viewable_id: @product.master.id,
            viewable_type: 'Spree::Variant'
          )
          render json: @image, serializer: ImageSerializer, status: :created
        else
          @image = @product.images.first
          @image.update(attachment: params[:file])
          render json: @image, serializer: ImageSerializer, status: :ok
        end
      end
    end
  end
end
