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
    product_ids = valid_products_relation.map(&:id)
    Spree::Product.where(id: product_ids)
  end

  def relation_with_sql
    product_ids = valid_products_sql.map(&:id)
    Spree::Product.where(id: product_ids)
  end

  def valid_products_sql
    query = <<-SQL
SELECT "spree_products".*
  FROM "spree_products"
 LEFT
  JOIN "spree_variants"
    ON "spree_variants"."product_id"    = "spree_products"."id"
   AND "spree_variants"."is_master"     = 'f'
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
 WHERE "exchanges"."order_cycle_id"     = ? OR "exchanges"."order_cycle_id" IS NULL
   AND "exchanges"."incoming"           = 'f' OR "exchanges"."incoming" IS NULL
   AND "exchanges"."receiver_id"        = ? OR "exchanges"."receiver_id" IS NULL
   AND ("spree_products".deleted_at IS NULL)
   AND ("spree_variants".deleted_at IS NULL)
   AND (o_inventory_items.id IS NULL
    OR o_inventory_items.visible        = ('t'))
    SQL
    Spree::Product.find_by_sql([query, distributor.id, order_cycle.id, distributor.id])
  end

  private

  attr_reader :order_cycle, :distributor

  def valid_products_relation
    Spree::Product
      .joins(variants: { exchange_variants: :exchange })
      .merge(distributor.inventory_variants)
      .merge(Exchange.in_order_cycle(order_cycle))
      .merge(Exchange.outgoing)
      .merge(Exchange.to_enterprise(distributor))
  end
end
