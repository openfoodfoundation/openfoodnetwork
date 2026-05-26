# frozen_string_literal: true

require 'open_food_network/scope_product_to_hub'

class ProductsRenderer
  include Pagy::Backend

  class NoProducts < RuntimeError; end
  DEFAULT_PER_PAGE = 10

  def initialize(distributor, order_cycle, customer, args = {}, **options)
    @distributor = distributor
    @order_cycle = order_cycle
    @customer = customer
    @args = args
    @options = options
  end

  def products_json
    raise NoProducts unless order_cycle && distributor && products

    ActiveModel::ArraySerializer.new(products,
                                     each_serializer: Api::ProductSerializer,
                                     current_order_cycle: order_cycle,
                                     current_distributor: distributor,
                                     variants: variants_for_shop_by_id,
                                     enterprise_fee_calculator:).to_json
  end

  def products
    return unless order_cycle

    @products ||= begin
      results = if enterprise_properties.present?
                  distributed_products.products_relation_incl_enterprise_properties
                else
                  distributed_products.products_relation
                end
      results = filter(results)

      paginated_products = paginate(results)

      if inventory_enabled?
        # Scope results with variant_overrides
        paginated_products.each { |product| product_scoper.scope(product) }
      end

      paginated_products
    end
  end

  private

  attr_reader :order_cycle, :distributor, :customer, :args, :options

  def product_scoper
    @product_scoper ||= OpenFoodNetwork::ScopeProductToHub.new(distributor)
  end

  def enterprise_fee_calculator
    OpenFoodNetwork::EnterpriseFeeCalculator.new distributor, order_cycle
  end

  def filter(query)
    ransack_results = query.ransack(args[:q]).result.to_a

    return ransack_results if enterprise_properties.blank?

    enterprise_properties_results = []
    if enterprise_properties.present?
      # We can't search on an association's scope with ransack, a work around is to define
      # the a scope on the parent (Spree::Product) but because we are joining on "first_variant"
      # to get the supplier it doesn't work, so we do the filtering manually here
      # see:
      #   OrderCycleDistributedProducts#products_relation
      enterprise_properties_results = query.
        where(producer_properties: { property_id: enterprise_property_ids }).
        where(inherits_properties: true)
    end

    if enterprise_properties_results.present? && with_properties.present?
      # apply "OR" between property search
      return ransack_results | enterprise_properties_results
    end

    # Intersect the result to apply "AND" with other search criteria
    return ransack_results.intersection(enterprise_properties_results) \
      unless enterprise_properties_results.empty?

    # We should get here but just in case we return the ransack results
    ransack_results
  end

  def enterprise_properties
    args[:q]&.slice("with_variants_enterprise_properties")
  end

  def enterprise_property_ids
    enterprise_properties["with_variants_enterprise_properties"]
  end

  def with_properties
    args[:q]&.dig("with_properties")
  end

  def paginate(results)
    _pagy, paginated_results = pagy_array(
      results,
      page: args[:page] || 1,
      limit: args[:per_page] || DEFAULT_PER_PAGE
    )

    paginated_results
  end

  def distributed_products
    OrderCycles::DistributedProductsService.new(distributor, order_cycle, customer, **options)
  end

  def variants_for_shop
    @variants_for_shop ||= begin
      variants = distributed_products.variants_relation.
        includes(:default_price, :product).
        where(product_id: products)

      if inventory_enabled?
        # Scope results with variant_overrides
        scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
        variants = variants.each { |v| scoper.scope(v) }
      end

      variants
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

  def inventory_enabled?
    options[:inventory_enabled] && !options[:variant_tag_enabled]
  end
end
