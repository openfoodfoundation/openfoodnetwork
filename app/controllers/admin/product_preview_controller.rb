# frozen_string_literal: true

module Admin
  class ProductPreviewController < Spree::Admin::BaseController
    helper Admin::ProductsHelper

    def show
      @product = Spree::Product.find(params[:id])
      authorize! :show, @product

      @grid_view = helpers.product_grid_view?
      @product_view = ProductPreviewRenderer.new(@product).product_view if @grid_view

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
