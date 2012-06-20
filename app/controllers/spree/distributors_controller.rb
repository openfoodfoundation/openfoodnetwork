module Spree
  class DistributorsController < BaseController
    def show
      options = {:distributor_id => params[:id]}
      options.merge(params.reject { |k,v| k == :id })

      @searcher = Config.searcher_class.new(options)
      @products = @searcher.retrieve_products
      render :template => 'spree/products/index'
    end
  end
end
