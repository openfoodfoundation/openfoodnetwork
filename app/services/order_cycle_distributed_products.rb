# frozen_string_literal: true

# Returns a (paginatable) AR object for the products or variants in stock for a given shop and OC.
# The stock-checking includes on_demand and stock level overrides from variant_overrides.
class OrderCycleDistributedProducts
  def initialize(distributor, order_cycle, customer)
    @distributor = distributor
    @order_cycle = order_cycle
    @customer = customer
  end

  def products_relation
    Spree::Product.where(id: stocked_products).group("spree_products.id")
  end

  def variants_relation
    order_cycle.
      variants_distributed_by(distributor).
      merge(stocked_variants_and_overrides).
      select("DISTINCT spree_variants.*")
  end

  private

  attr_reader :distributor, :order_cycle, :customer

  def stocked_products
    order_cycle.
      variants_distributed_by(distributor).
      merge(stocked_variants_and_overrides).
      select("DISTINCT spree_variants.product_id")
  end

  def stocked_variants_and_overrides
    stocked_variants = Spree::Variant.
      joins("LEFT OUTER JOIN variant_overrides ON variant_overrides.variant_id = spree_variants.id
            AND variant_overrides.hub_id = #{distributor.id}").
      joins(:stock_items).
      where(query_stock_with_overrides)

    ProductTagRulesFilterer.new(distributor, customer, stocked_variants).call
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
