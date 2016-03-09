require 'open_food_network/scope_product_to_hub'

module OpenFoodNetwork
  class ProductsRenderer
    class NoProducts < Exception; end

    def initialize(distributor, order_cycle)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def products
      products = products_for_shop

      if products
        enterprise_fee_calculator = EnterpriseFeeCalculator.new @distributor, @order_cycle

        ActiveModel::ArraySerializer.new(products,
                                         each_serializer: Api::ProductSerializer,
                                         current_order_cycle: @order_cycle,
                                         current_distributor: @distributor,
                                         variants: variants_for_shop_by_id,
                                         master_variants: master_variants_for_shop_by_id,
                                         enterprise_fee_calculator: enterprise_fee_calculator,
                                        ).to_json
      else
        raise NoProducts.new
      end
    end


    private

    def products_for_shop
      if @order_cycle
        scoper = ScopeProductToHub.new(@distributor)

        @order_cycle.
          valid_products_distributed_by(@distributor).
          order(taxon_order).
          each { |p| scoper.scope(p) }.
          select { |p| !p.deleted? && p.has_stock_for_distribution?(@order_cycle, @distributor) }
      end
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
      # We use the in_stock? method here instead of the in_stock scope because we need to
      # look up the stock as overridden by VariantOverrides, and the scope method is not affected
      # by them.
      scoper = OpenFoodNetwork::ScopeVariantToHub.new(@distributor)
      Spree::Variant.
        for_distribution(@order_cycle, @distributor).
        each { |v| scoper.scope(v) }.
        select(&:in_stock?)
    end

    def variants_for_shop_by_id
      index_by_product_id all_variants_for_shop.reject(&:is_master)
    end

    def master_variants_for_shop_by_id
      index_by_product_id all_variants_for_shop.select(&:is_master)
    end

    def index_by_product_id(variants)
      variants.inject({}) do |vs, v|
        vs[v.product_id] ||= []
        vs[v.product_id] << v
        vs
      end
    end
  end
end
