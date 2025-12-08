# frozen_string_literal: true

# Returns a (paginatable) AR object for the products or variants in stock for a given shop and OC.
# The stock-checking includes on_demand and stock level overrides from variant_overrides.

module OrderCycles
  class DistributedProductsService # rubocop:disable Metrics/ClassLength
    def initialize(distributor, order_cycle, customer, **options)
      @distributor = distributor
      @order_cycle = order_cycle
      @customer = customer
      @options = options
    end

    def products_relation
      relation_by_sorting.order(Arel.sql(order))
    end

    def products_relation_incl_supplier_properties
      query = relation_by_sorting

      query = supplier_property_join(query)

      query.order(Arel.sql(order))
    end

    def variants_relation
      order_cycle.
        variants_distributed_by(distributor).
        merge(variants).
        select("DISTINCT spree_variants.*")
    end

    private

    attr_reader :distributor, :order_cycle, :customer, :options

    def relation_by_sorting
      query = Spree::Product.where(id: stocked_products)

      if sorting == "by_producer"
        # Joins on the first product variant to allow us to filter product by supplier. This is so
        # enterprise can display product sorted by supplier in a custom order on their shopfront.
        #
        # Caveat, the supplier sorting won't work properly if there are multiple variant with
        # different supplier for a given product.
        query.
          joins("LEFT JOIN (SELECT DISTINCT ON(product_id) id, product_id, supplier_id
                            FROM spree_variants WHERE deleted_at IS NULL) first_variant
                            ON spree_products.id = first_variant.product_id").
          select("spree_products.*, first_variant.supplier_id").
          group("spree_products.id, first_variant.supplier_id")
      elsif sorting == "by_category"
        # Joins on the first product variant to allow us to filter product by taxon.  # This is so
        # enterprise can display product sorted by category in a custom order on their shopfront.
        #
        # Caveat, the category sorting won't work properly if there are multiple variant with
        # different category for a given product.
        query.
          joins("LEFT JOIN (
                   SELECT DISTINCT ON(product_id) id, product_id, primary_taxon_id,
                   supplier_id
                   FROM spree_variants WHERE deleted_at IS NULL
                 ) first_variant ON spree_products.id = first_variant.product_id").
          select("spree_products.*, first_variant.primary_taxon_id").
          group("spree_products.id, first_variant.primary_taxon_id")
      else
        query.group("spree_products.id")
      end
    end

    def sorting
      distributor.preferred_shopfront_product_sorting_method
    end

    def sorting_by_producer?
      sorting == "by_producer" &&
        distributor.preferred_shopfront_producer_order.present?
    end

    def sorting_by_category?
      sorting == "by_category" &&
        distributor.preferred_shopfront_taxon_order.present?
    end

    def supplier_property_join(query)
      query.joins("
        JOIN enterprises ON enterprises.id = first_variant.supplier_id
        LEFT OUTER JOIN producer_properties ON producer_properties.producer_id = enterprises.id
      ")
    end

    def order
      if sorting_by_producer?
        order_by_producer = distributor
          .preferred_shopfront_producer_order
          .split(",").map { |id| "first_variant.supplier_id=#{id} DESC" }
          .join(", ")

        "#{order_by_producer}, spree_products.name ASC, spree_products.id ASC"
      elsif sorting_by_category?
        order_by_category = distributor
          .preferred_shopfront_taxon_order
          .split(",").map { |id| "first_variant.primary_taxon_id=#{id} DESC" }
          .join(", ")

        "#{order_by_category}, spree_products.name ASC, spree_products.id ASC"
      else
        "spree_products.name ASC, spree_products.id"
      end
    end

    def stocked_products
      order_cycle.
        variants_distributed_by(distributor).
        merge(variants).
        select("DISTINCT spree_variants.product_id")
    end

    def variants
      return tag_rule_filtered_variants if options[:variant_tag_enabled]

      return stocked_variants_and_overrides if options[:inventory_enabled]

      stocked_variants
    end

    def stocked_variants
      Spree::Variant.joins(:stock_items).where(query_stock)
    end

    def tag_rule_filtered_variants
      VariantTagRulesFilterer.new(distributor:, customer:,
                                  variants_relation: stocked_variants).call
    end

    def stocked_variants_and_overrides
      stocked_variants = Spree::Variant.
        joins("LEFT OUTER JOIN variant_overrides ON variant_overrides.variant_id = spree_variants.id
              AND variant_overrides.hub_id = #{distributor.id}").
        joins(:stock_items).
        where(query_stock_with_overrides)

      ProductTagRulesFilterer.new(distributor, customer, stocked_variants).call
    end

    def query_stock
      "( #{variant_on_demand} OR #{variant_in_stock} )"
    end

    def query_stock_with_overrides
      "( #{variant_not_overriden} AND ( #{variant_on_demand} OR #{variant_in_stock} ) )
        OR ( #{variant_overriden} AND ( #{override_on_demand} OR #{override_in_stock} ) )
        OR ( #{variant_overriden} AND ( #{override_on_demand_null} AND #{variant_on_demand} ) )
        OR ( #{variant_overriden} AND ( #{override_on_demand_null}
                                        AND #{variant_not_on_demand} AND #{variant_in_stock} ) )"
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
  end
end
