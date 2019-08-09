# Finds valid products distributed by a particular distributor in an order cycle
#
# If a product without variants is added to an order cycle, and then some
# variants are added to that product, but not the order cycle, then the master
# variant should not available for customers to purchase. This class filters
# out such products so that the customer cannot purchase them.
class OrderCycleDistributedProducts
  def initialize(order_cycle, distributor)
    @order_cycle = order_cycle
    @distributor = distributor
  end

  # Returns an ActiveRecord relation without invalid products. Check
  # #valid_products_distributed_by for details
  #
  # @return [ActiveRecord::Relation<Spree::Product>]
  def relation
    all_distributed_product_ids = all_distributed_products.map(&:product_id)
    product_ids_with_obsolete_master = products_with_obsolete_master.map(&:id)

    valid_product_ids = all_distributed_product_ids - product_ids_with_obsolete_master

    Spree::Product.where(id: valid_product_ids)
  end

  private

  attr_reader :order_cycle, :distributor

  def all_distributed_products
    order_cycle
      .variants_distributed_by(distributor)
      .select(:product_id)
      .group(:product_id)
  end

  def products_with_obsolete_master
    query = <<-SQL
SELECT "spree_products".*
  FROM "spree_products"
  LEFT
  JOIN "spree_variants"
    ON "spree_variants"."product_id"    = "spree_products"."id"
   AND "spree_variants"."deleted_at" IS NULL
  LEFT
  JOIN "exchange_variants"
    ON "exchange_variants"."variant_id" = "spree_variants"."id"
  LEFT
  JOIN "exchanges"
    ON "exchanges"."id"                 = "exchange_variants"."exchange_id"
  LEFT OUTER
  JOIN (
    SELECT *
      from inventory_items
 WHERE enterprise_id                    = ?) AS o_inventory_items
    ON o_inventory_items.variant_id     = spree_variants.id
   AND ("spree_products".deleted_at IS NULL)
   AND ("spree_variants".deleted_at IS NULL)
   AND (o_inventory_items.id IS NULL
    OR o_inventory_items.visible        = ('t'))
 GROUP BY "spree_products"."id"
HAVING COUNT(*) > 1
   AND bool_or(is_master = true AND exchanges.id IS NOT NULL)
   AND COUNT(exchanges.id) = 1
    SQL

    Spree::Product.find_by_sql(
      [query, distributor.id]
    )
  end
end
