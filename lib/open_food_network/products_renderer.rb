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
        each { |product| scoper.scope(product) }.
        select do |product|
          product.has_stock_for_distribution?(@order_cycle, @distributor)
        end
    end

    def distributed_products
      @order_cycle.
        variants_distributed_by(@distributor).
        includes(:product).
        select(:product_id)
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
