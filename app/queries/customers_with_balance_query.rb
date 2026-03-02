# frozen_string_literal: true

# Adds an aggregated 'balance_value' to each customer based on their order history
#
class CustomersWithBalanceQuery
  def initialize(customers)
    @customers = customers
  end

  def call
    @customers.
      joins(left_join_complete_orders).
      group("customers.id").
      select("customers.*").
      select("#{outstanding_balance_sum} AS balance_value").
      select("#{available_credit} AS credit_value")
  end

  private

  # The resulting orders are in states that belong after the checkout. Only these can be considered
  # for a customer's balance.
  def left_join_complete_orders
    <<~SQL.squish
      LEFT JOIN spree_orders ON spree_orders.customer_id = customers.id
        AND #{finalized_states.to_sql}
    SQL
  end

  def finalized_states
    states = Spree::Order::FINALIZED_STATES.map { |state| Arel::Nodes.build_quoted(state) }
    Arel::Nodes::In.new(Spree::Order.arel_table[:state], states)
  end

  def outstanding_balance_sum
    "SUM(#{OutstandingBalanceQuery.new.statement})::float"
  end

  def available_credit
    <<~SQL.squish
      CASE WHEN EXISTS (#{available_credit_subquery}) THEN (#{available_credit_subquery})#{' '}
      ELSE 0.00 END
    SQL
  end

  def available_credit_subquery
    <<~SQL.squish
      SELECT balance
      FROM customer_account_transactions
      WHERE customer_account_transactions.customer_id = customers.id
      ORDER BY id desc
      LIMIT 1
    SQL
  end
end
