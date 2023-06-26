# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

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

      scope_to_in_stock_only if scope_to_in_stock_only?
      scope_to_schedule if params[:schedule_id]
      scope_to_order_cycle if params[:order_cycle_id]
      scope_to_distributor if params[:distributor_id]

      @variants
    end

    private

    attr_reader :params

    def search_params
      { product_name_cont: params[:q], sku_cont: params[:q], product_sku_cont: params[:q] }
    end

    def query_scope
      Spree::Variant.
        ransack(search_params.merge(m: 'or')).
        result.
        order("spree_products.name, display_name, display_as, spree_products.variant_unit_name").
        includes(:product).
        joins(:product)
    end

    def distributor
      Enterprise.find params[:distributor_id]
    end

    def scope_to_schedule
      @variants = @variants.in_schedule(params[:schedule_id])
    end

    def scope_to_order_cycle
      @variants = @variants.in_order_cycle(params[:order_cycle_id])
    end

    def scope_to_distributor
      if params[:eligible_for_subscriptions]
        scope_to_eligible_for_subscriptions_in_distributor
      else
        scope_to_available_for_orders_in_distributor
      end
    end

    def scope_to_available_for_orders_in_distributor
      @variants = @variants.in_distributor(distributor)
      scope_variants_to_distributor(@variants, distributor)
    end

    def scope_to_eligible_for_subscriptions_in_distributor
      eligible_variants_scope =
        OrderManagement::Subscriptions::VariantsList.eligible_variants(distributor)
      @variants = @variants.merge(eligible_variants_scope)
      scope_variants_to_distributor(@variants, distributor)
    end

    def scope_to_in_stock_only
      @variants = @variants.joins(
        "INNER JOIN spree_stock_items ON spree_stock_items.variant_id = spree_variants.id
         LEFT JOIN variant_overrides ON variant_overrides.variant_id = spree_variants.id AND
                                        variant_overrides.hub_id = #{distributor.id}"
      ).where("
        variant_overrides.on_demand IS TRUE OR
        variant_overrides.count_on_hand > 0 OR
        (variant_overrides.on_demand IS NULL AND spree_stock_items.backorderable IS TRUE) OR
        (variant_overrides.count_on_hand IS NULL AND spree_stock_items.count_on_hand > 0)
      ")
    end

    def scope_to_in_stock_only?
      params[:distributor_id] && params[:include_out_of_stock] != "1"
    end

    def scope_variants_to_distributor(variants, distributor)
      scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
      # Perform scoping after all filtering is done.
      # Filtering could be a problem on scoped variants.
      variants.each { |v| scoper.scope(v) }
    end
  end
end
