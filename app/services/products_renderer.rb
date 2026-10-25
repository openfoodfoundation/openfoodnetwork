# frozen_string_literal: true

require 'open_food_network/scope_product_to_hub'

class ProductsRenderer
  include Pagy::Method

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

  # Generate read only data, with variants filtered for shop
  def products_view
    products.map do |product|
      attrs = product.slice(*ViewData::Product.members)
      attrs[:variants] = variants_view(product)
      ViewData::Product.new(**attrs)
    end
  end

  private

  attr_reader :order_cycle, :distributor, :customer, :args, :options

  def variants_view(product)
    simple_product = ViewData::SimpleProduct.new(**product.slice(*ViewData::SimpleProduct.members))

    variants_for_shop_by_id[product.id].map do |variant|
      presenter = VariantPresenter.new(
        variant:, distributor:, order_cycle:, enterprise_fee_calculator:
      )

      ViewData::Variant.new(
        **variant.slice(:id, :on_demand, :display_name, :name_to_display,
                        :unit_to_display, :price, :enterprise, :producer),
        on_hand: on_hand(variant),
        price_with_fees: presenter.price_with_fees,
        display_price_with_fees: presenter.display_price_with_fees,
        unit_price: presenter.unit_price,
        display_unit_price: presenter.display_unit_price,
        product: simple_product
      )
    end
  end

  # Spree::Variant#on_hand sums stock in the database on every call, because stock is live and
  # the caller may have just changed it. Rendering the shop doesn't write stock, so read the
  # preloaded rows instead of querying once per variant.
  #
  # Variant overrides replace the producer's stock entirely, so leave those to the variant.
  def on_hand(variant)
    return variant.on_hand if inventory_enabled?

    variant.stock_items.sum { |stock_item| stock_item.count_on_hand.to_i }
  end

  def products
    return unless order_cycle

    @products ||= begin
      results = filter(distributed_products.products_relation)

      paginated_products = paginate(results)

      if inventory_enabled?
        # Scope results with variant_overrides
        paginated_products.each { |product| product_scoper.scope(product) }
      end

      paginated_products
    end
  end

  def product_scoper
    @product_scoper ||= OpenFoodNetwork::ScopeProductToHub.new(distributor)
  end

  def enterprise_fee_calculator
    @enterprise_fee_calculator ||= OpenFoodNetwork::EnterpriseFeeCalculator.new(
      distributor, order_cycle
    )
  end

  def filter(query)
    query.ransack(args[:q]).result.to_a
  end

  def taxon_ids
    args[:q]&.dig("variants_primary_taxon_id_in_any")
  end

  def paginate(results)
    # ProductsRenderer is a PORO, not a controller: pagy always builds a Pagy::Request from
    # the :request option (falling back to #request otherwise), so it needs an explicit
    # params hash here rather than reading from an actual Rack request.
    _pagy, paginated_results = pagy(
      :offset,
      results,
      page: args[:page] || 1,
      limit: args[:per_page] || DEFAULT_PER_PAGE,
      request: { params: {} }
    )

    paginated_results
  end

  def distributed_products
    OrderCycles::DistributedProductsService.new(distributor, order_cycle, customer, **options)
  end

  def variants_for_shop
    @variants_for_shop ||= begin
      variants = distributed_products.variants_relation.
        includes(:default_price, :product, :enterprise, :stock_items,
                 source_variants: :enterprise).
        where(product_id: products)

      # The taxon filter is applied to products via ransack, but a product is matched as soon
      # as any of its variants has the taxon. Apply the same filter to the variants so that
      # only the variants in the requested categories are rendered.
      variants = variants.where(primary_taxon_id: taxon_ids) if taxon_ids.present?

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
