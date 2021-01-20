# frozen_string_literal: true

# Fetches the customers of the specified enterprise including the aggregated balance across the
# customer's orders. That is, we get the total balance for each customer with this enterprise.
class CustomersWithBalance
  def initialize(enterprise)
    @enterprise = enterprise
  end

  def query
    Customer.of(enterprise).
      joins(left_join_complete_orders).
      group("customers.id").
      select("customers.*").
      select(outstanding_balance_sum)
  end

  private

  attr_reader :enterprise

  def outstanding_balance_sum
    "SUM(#{OutstandingBalance.new.statement}) AS balance_value"
  end

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
end
