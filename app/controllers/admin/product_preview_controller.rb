# frozen_string_literal: true

module Admin
  class ProductPreviewController < Spree::Admin::BaseController
    def show
      @id = params[:id]
      # TODO load product data based on param
      respond_with do |format|
        format.turbo_stream {
          render "admin/products_v3/product_preview", status: :ok, locals: { id: @id }
        }
      end
    end
  end
end
