# frozen_string_literal: true

module Admin
  class ProductPreviewController < Spree::Admin::BaseController
    def show
      @product = Spree::Product.find(params[:id])
      authorize! :show, @product

      respond_with do |format|
        format.turbo_stream {
          render "admin/products_v3/product_preview", status: :ok
        }
      end
    end

    private

    def model_class
      Spree::Product
    end
  end
end
