# frozen_string_literal: true

require 'open_food_network/scope_product_to_hub'

class ProductsRenderer
  include Pagy::Backend

  class NoProducts < RuntimeError; end
  DEFAULT_PER_PAGE = 10

  def initialize(distributor, order_cycle, customer, args = {})
    @distributor = distributor
    @order_cycle = order_cycle
    @customer = customer
    @args = args
  end

  def products_json
    raise NoProducts unless order_cycle && distributor && products

    ActiveModel::ArraySerializer.new(products,
                                     each_serializer: Api::ProductSerializer,
                                     current_order_cycle: order_cycle,
                                     current_distributor: distributor,
                                     variants: variants_for_shop_by_id,
                                     enterprise_fee_calculator: enterprise_fee_calculator).to_json
  end

  private

  attr_reader :order_cycle, :distributor, :customer, :args

  def products
    return unless order_cycle

    @products ||= begin
      results = distributed_products.
        products_relation.
        order(Arel.sql(products_order))

      filter_and_paginate(results).
        each { |product| product_scoper.scope(product) } # Scope results with variant_overrides
    end
  end

  def product_scoper
    @product_scoper ||= OpenFoodNetwork::ScopeProductToHub.new(distributor)
  end

  def enterprise_fee_calculator
    OpenFoodNetwork::EnterpriseFeeCalculator.new distributor, order_cycle
  end

  def filter_and_paginate(query)
    results = query.ransack(args[:q]).result

    _pagy, paginated_results = pagy(
      results,
      page: args[:page] || 1,
      items: args[:per_page] || DEFAULT_PER_PAGE
    )

    paginated_results
  end

  def distributed_products
    OrderCycleDistributedProducts.new(distributor, order_cycle, customer)
  end

  def products_order
    if (distributor.preferred_shopfront_product_sorting_method == "by_producer") &&
       distributor.preferred_shopfront_producer_order.present?
      distributor
        .preferred_shopfront_producer_order
        .split(",").map { |id| "spree_products.supplier_id=#{id} DESC" }
        .join(", ") + ", spree_products.name ASC, spree_products.id ASC"
    elsif distributor.preferred_shopfront_product_sorting_method == "by_category" &&
          distributor.preferred_shopfront_taxon_order.present?
      distributor
        .preferred_shopfront_taxon_order
        .split(",").map { |id| "spree_products.primary_taxon_id=#{id} DESC" }
        .join(", ") + ", spree_products.name ASC, spree_products.id ASC"
    else
      "spree_products.name ASC, spree_products.id"
    end
  end

  def variants_for_shop
    @variants_for_shop ||= begin
      scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)

      distributed_products.variants_relation.
        includes(:default_price, :stock_locations, :product).
        where(product_id: products).
        each { |v| scoper.scope(v) } # Scope results with variant_overrides
    end
  end

  def variants_for_shop_by_id
    index_by_product_id variants_for_shop
  end

  def index_by_product_id(variants)
    variants.each_with_object({}) do |v, vs|
      vs[v.product_id] ||= []
      vs[v.product_id] << v
    end
  end
end
