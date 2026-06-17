# frozen_string_literal: true

module Api
  module V0
    class ProductImagesController < Api::V0::BaseController
      respond_to :json

      def update_product_image
        product = Spree::Product.find(params[:product_id])
        authorize! :update, product

        previous_image = product.image
        image = Spree::Image.new(
          viewable_id: product.id,
          viewable_type: 'Spree::Product'
        )
        image.attachment.attach(params[:file])

        success_status = previous_image.present? ? :ok : :created

        if image.save
          previous_image&.destroy!
          render json: image, serializer: ImageSerializer, status: success_status
        else
          error_json = { errors: image.errors.full_messages }
          render json: error_json, status: :unprocessable_entity
        end
      end
    end
  end
end
