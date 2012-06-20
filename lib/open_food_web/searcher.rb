require 'spree/core/search/base'

module OpenFoodWeb
  class Searcher < Spree::Core::Search::Base

    def get_base_scope
      base_scope = super

      base_scope = base_scope.in_supplier(supplier_id) if supplier_id
      base_scope = base_scope.in_distributor(distributor_id) if distributor_id

      base_scope
    end


    def prepare(params)
      super(params)
      @properties[:supplier_id] = params[:supplier_id]
      @properties[:distributor_id] = params[:distributor_id]
    end

  end
end
