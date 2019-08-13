# Scopes a passed AR relation to the products supplied in the specified order
# cycle
class SuppliedInOrderCycleQuery
  def initialize(relation, order_cycle_id)
    @relation = relation
    @order_cycle_id = order_cycle_id
  end

  def call
    relation
      .joins(suppliers_exchanges)
      .where('suppliers_exchanges.order_cycle_id = ?', order_cycle_id)
  end

  private

  attr_reader :relation, :order_cycle_id

  def suppliers_exchanges
    <<-SQL.strip_heredoc
      INNER JOIN exchanges AS suppliers_exchanges
      ON suppliers_exchanges.sender_id = spree_products.supplier_id
    SQL
  end
end

