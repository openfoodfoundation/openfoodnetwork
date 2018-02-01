# Used to return a set of variants which match the criteria provided
# A query string is required, which will be match to the name and/or SKU of a product
# Further restrictions on the schedule, order_cycle or distributor through which the
# products are available are also possible

module OpenFoodNetwork
  class ScopeVariantsForSearch
    def initialize(params)
      @params = params
    end

    def search
      @variants = query_scope

      scope_to_schedule if params[:schedule_id]
      scope_to_order_cycle if params[:order_cycle_id]
      scope_to_distributor if params[:distributor_id]

      @variants
    end

    private

    attr_reader :params

    def search_params
      { :product_name_cont => params[:q], :sku_cont => params[:q] }
    end

    def query_scope
      Spree::Variant.where(is_master: false).ransack(search_params.merge(:m => 'or')).result
    end

    def scope_to_schedule
      @variants = @variants.in_schedule(params[:schedule_id])
    end

    def scope_to_order_cycle
      @variants = @variants.in_order_cycle(params[:order_cycle_id])
    end

    def scope_to_distributor
      distributor = Enterprise.find params[:distributor_id]
      @variants = @variants.in_distributor(distributor)
      scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
      # Perform scoping after all filtering is done.
      # Filtering could be a problem on scoped variants.
      @variants.each { |v| scoper.scope(v) }
    end
  end
end
