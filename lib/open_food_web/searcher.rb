require 'spree/core/search/base'

module OpenFoodWeb
  class Searcher < Spree::Core::Search::Base

    # Do not perform pagination
    def retrieve_products
      @products_scope = get_base_scope
      curr_page = page || 1

      @products = @products_scope.includes([:master])
    end

    def get_base_scope
      base_scope = super

      # The concern of separating products by distributor and order cycle is dealt with in
      # a few other places: OpenFoodWeb::SplitProductsByDistributor (for splitting the main
      # product display) and Spree::BaseHelper decorator (for taxon counts).

      base_scope = base_scope.in_supplier_or_distributor(enterprise_id) if enterprise_id
      base_scope = base_scope.in_supplier(supplier_id) if supplier_id
      base_scope = base_scope.in_distributor(distributor_id) if distributor_id

      base_scope
    end


    def prepare(params)
      super(params)
      @properties[:enterprise_id] = params[:enterprise_id]
      @properties[:supplier_id] = params[:supplier_id]
      @properties[:distributor_id] = params[:distributor_id]
    end

  end
end
