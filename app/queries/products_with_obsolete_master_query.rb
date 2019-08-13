# Returns the products that have an obsolete master those that:
# * their master is in distribution in an order cycle
# * their variants are not in distribution
class ProductsWithObsoleteMasterQuery
  def initialize(relation = Spree::Product, order_cycle_id)
    @relation = relation
    @order_cycle_id = order_cycle_id
  end

  # This gets the variants, including master, for each product and then picks
  # the ones that match the criteria for being obsolete through the HAVING
  # clause.
  def all
    products = relation
      .joins(left_join_variants)
      .joins(left_join_exchange_variants)
      .joins(left_join_exchanges)
      .where(not_incoming_exchanges)
      .group('spree_products.id')
      .having(master_distributed_but_not_variants)

    SuppliedInOrderCycleQuery.new(products, order_cycle_id).call
  end

  private

  attr_reader :relation, :order_cycle_id

  def left_join_variants
    <<-SQL.strip_heredoc
      LEFT JOIN "spree_variants"
      ON "spree_variants"."product_id" = "spree_products"."id"
        AND "spree_variants"."deleted_at" IS NULL
    SQL
  end

  def left_join_exchange_variants
    <<-SQL.strip_heredoc
      LEFT JOIN "exchange_variants"
      ON "exchange_variants"."variant_id" = "spree_variants"."id"
    SQL
  end

  def left_join_exchanges
    <<-SQL.strip_heredoc
      LEFT JOIN "exchanges" AS obsolete_exchanges
      ON "obsolete_exchanges"."id" = "exchange_variants"."exchange_id"
    SQL
  end

  def not_incoming_exchanges
    'obsolete_exchanges.incoming = false OR obsolete_exchanges.incoming IS NULL'
  end

  # Selects the groups that have more than a row, aka. product with variants
  # whose master is not distributed using the PostgreSQL `bool_or` function.
  # Lastly, it checks that the only the master is being distributed through an
  # exchange.
  def master_distributed_but_not_variants
    <<-SQL.strip_heredoc
      COUNT(*) > 1
      AND bool_or(is_master = true AND exchange_variants.id IS NOT NULL)
      AND COUNT(exchange_variants.id) = 1
    SQL
  end
end
