module Api
  class ProductImagesController < Spree::Api::BaseController
    respond_to :json

    def update_product_image
      @product = Spree::Product.find(params[:product_id])
      authorize! :update, @product

      if @product.images.first.nil?
        @image = Spree::Image.create(attachment: params[:file], viewable_id: @product.master.id, viewable_type: 'Spree::Variant')
        respond_with(@image, status: 201)
      else
        @image = @product.images.first
        @image.update_attributes(attachment: params[:file])
        respond_with(@image, status: 200)
      end
    end
  end
end
