# frozen_string_literal: true

module Admin
  class ProductsV3Controller < Spree::Admin::BaseController
    def index
      @page = params[:page] || 1
      @per_page = params[:per_page] || 15
    end
  end
end
