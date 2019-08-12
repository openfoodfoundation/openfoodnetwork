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
    valid_product_ids = order_cycle
      .variants_distributed_by(distributor)
      .joins(<<-SQL.strip_heredoc)
        LEFT JOIN (
          #{products_with_obsolete_master.select('spree_products.id').to_sql}
        ) AS products_with_obsolete_master
        ON spree_variants.product_id = products_with_obsolete_master.id
      SQL
      .where('products_with_obsolete_master.id IS NULL')
      .select(:product_id)
      .group(:product_id)

    Spree::Product.where(id: valid_product_ids)
  end

  private

  attr_reader :order_cycle, :distributor

  # TODO: filter by products supplied by the OC suppliers so we don't go through the whole products table.
  def products_with_obsolete_master
    Spree::Product
      .joins('INNER JOIN exchanges AS exchanges_suppliers ON exchanges_suppliers.sender_id = spree_products.supplier_id')
      .joins('LEFT JOIN "spree_variants" ON "spree_variants"."product_id" = "spree_products"."id" AND "spree_variants"."deleted_at" IS NULL')
      .joins('LEFT JOIN "exchange_variants" ON "exchange_variants"."variant_id" = "spree_variants"."id"')
      .joins('LEFT JOIN "exchanges" AS obsolete_exchanges ON "obsolete_exchanges"."id" = "exchange_variants"."exchange_id"')
      .where('exchanges_suppliers.order_cycle_id = ?', order_cycle.id)
      .where('obsolete_exchanges.incoming = false OR obsolete_exchanges.incoming IS NULL')
      .group('"spree_products"."id"')
      .having(<<-SQL.strip_heredoc)
        COUNT(*) > 1
        AND bool_or(is_master = true
        AND exchange_variants.id IS NOT NULL)
        AND COUNT(exchange_variants.id) = 1
      SQL
  end
end
