module Spree
  class SuppliersController < BaseController
    helper 'spree/products'

    def show
      options = {:supplier_id => params[:id]}
      options.merge(params.reject { |k,v| k == :id })

      @searcher = Config.searcher_class.new(options)
      @products = @searcher.retrieve_products
      render :template => 'spree/products/index'
    end
  end
end
