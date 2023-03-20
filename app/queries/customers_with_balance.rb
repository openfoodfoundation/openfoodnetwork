# frozen_string_literal: true

# Adds an aggregated 'balance_value' to each customer based on their order history
#
class CustomersWithBalance
  def initialize(customers)
    @customers = customers
  end

  def query
    @customers.
      joins(left_join_complete_orders).
      group("customers.id").
      select("customers.*").
      select("#{outstanding_balance_sum} AS balance_value")
  end

  private

  # The resulting orders are in states that belong after the checkout. Only these can be considered
  # for a customer's balance.
  def left_join_complete_orders
    <<-SQL.strip_heredoc
      LEFT JOIN spree_orders ON spree_orders.customer_id = customers.id
        AND #{finalized_states.to_sql}
    SQL
  end

  def finalized_states
    states = Spree::Order::FINALIZED_STATES.map { |state| Arel::Nodes.build_quoted(state) }
    Arel::Nodes::In.new(Spree::Order.arel_table[:state], states)
  end

  def outstanding_balance_sum
    "SUM(#{OutstandingBalance.new.statement})::float"
  end
end
