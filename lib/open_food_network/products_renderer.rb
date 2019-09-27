require 'open_food_network/scope_product_to_hub'

module OpenFoodNetwork
  class ProductsRenderer
    class NoProducts < RuntimeError; end

    def initialize(distributor, order_cycle)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def products_json
      products = load_products

      if products
        enterprise_fee_calculator = EnterpriseFeeCalculator.new @distributor, @order_cycle

        ActiveModel::ArraySerializer.new(products,
                                         each_serializer: Api::ProductSerializer,
                                         current_order_cycle: @order_cycle,
                                         current_distributor: @distributor,
                                         variants: variants_for_shop_by_id,
                                         master_variants: master_variants_for_shop_by_id,
                                         enterprise_fee_calculator: enterprise_fee_calculator,).to_json
      else
        raise NoProducts
      end
    end

    private

    def load_products
      return unless @order_cycle

      Spree::Product.where(id: distributed_products).
        order(taxon_order).
        each { |product| scoper.scope(product) }
    end

    def distributed_products
      @order_cycle.
        variants_distributed_by(@distributor).
        merge(stocked_variants_with_overrides).
        select("DISTINCT spree_variants.product_id")
    end

    def stocked_variants_with_overrides
      Spree::Variant.
        joins("LEFT OUTER JOIN variant_overrides ON variant_overrides.variant_id = spree_variants.id AND variant_overrides.hub_id = #{@distributor.id}").
        joins(:stock_items).
        where(query_stock_with_overrides)
    end

    def query_stock_with_overrides
      "( #{variant_not_overriden} AND ( #{variant_in_stock} OR #{variant_on_demand} ) )
        OR ( #{variant_overriden} AND ( #{override_on_demand} OR #{override_in_stock} ) )
        OR ( #{variant_overriden} AND ( #{override_on_demand_null} AND #{variant_on_demand} ) )
        OR ( #{variant_overriden} AND ( #{override_on_demand_null} AND #{variant_not_on_demand} AND #{variant_in_stock} ) )"
    end

    def variant_not_overriden
      "variant_overrides.id IS NULL"
    end

    def variant_overriden
      "variant_overrides.id IS NOT NULL"
    end

    def variant_in_stock
      "spree_stock_items.count_on_hand > 0"
    end

    def variant_on_demand
      "spree_stock_items.backorderable IS TRUE"
    end

    def variant_not_on_demand
      "spree_stock_items.backorderable IS FALSE"
    end

    def override_on_demand
      "variant_overrides.on_demand IS TRUE"
    end

    def override_in_stock
      "variant_overrides.count_on_hand > 0"
    end

    def override_on_demand_null
      "variant_overrides.on_demand IS NULL"
    end

    def scoper
      ScopeProductToHub.new(@distributor)
    end

    def taxon_order
      if @distributor.preferred_shopfront_taxon_order.present?
        @distributor
          .preferred_shopfront_taxon_order
          .split(",").map { |id| "primary_taxon_id=#{id} DESC" }
          .join(",") + ", name ASC"
      else
        "name ASC"
      end
    end

    def all_variants_for_shop
      @all_variants_for_shop ||= begin
                                   # We use the in_stock? method here instead of the in_stock scope
                                   # because we need to look up the stock as overridden by
                                   # VariantOverrides, and the scope method is not affected by them.
                                   scoper = OpenFoodNetwork::ScopeVariantToHub.new(@distributor)
                                   Spree::Variant.
                                     for_distribution(@order_cycle, @distributor).
                                     each { |v| scoper.scope(v) }.
                                     select(&:in_stock?)
                                 end
    end

    def variants_for_shop_by_id
      index_by_product_id all_variants_for_shop.reject(&:is_master)
    end

    def master_variants_for_shop_by_id
      index_by_product_id all_variants_for_shop.select(&:is_master)
    end

    def index_by_product_id(variants)
      variants.each_with_object({}) do |v, vs|
        vs[v.product_id] ||= []
        vs[v.product_id] << v
      end
    end
  end
end
