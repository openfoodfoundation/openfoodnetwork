# frozen_string_literal: true

class CustomersWithBalance
  def initialize(enterprise)
    @enterprise = enterprise
  end

  def query
    Customer.of(enterprise).
      joins(left_join_complete_orders).
      group("customers.id").
      select("customers.*").
      select(outstanding_balance)
  end

  private

  attr_reader :enterprise

  # Arel doesn't support CASE statements until v7.1.0 so we'll have to wait with SQL literals
  # a little longer. See https://github.com/rails/arel/pull/400 for details.
  def outstanding_balance
    <<-SQL.strip_heredoc
       SUM(
         CASE WHEN state IN #{non_fulfilled_states_group.to_sql} THEN payment_total
              WHEN state IS NOT NULL THEN payment_total - total
         ELSE 0 END
       ) AS balance_value
    SQL
  end

  # The resulting orders are in states that belong after the checkout. Only these can be considered
  # for a customer's balance.
  def left_join_complete_orders
    <<-SQL.strip_heredoc
      LEFT JOIN spree_orders ON spree_orders.customer_id = customers.id
        AND #{complete_orders.to_sql}
    SQL
  end

  def complete_orders
    states_group = prior_to_completion_states.map { |state| Arel::Nodes.build_quoted(state) }
    Arel::Nodes::NotIn.new(Spree::Order.arel_table[:state], states_group)
  end

  def non_fulfilled_states_group
    states_group = non_fulfilled_states.map { |state| Arel::Nodes.build_quoted(state) }
    Arel::Nodes::Grouping.new(states_group)
  end

  # All the states an order can be in before completing the checkout
  def prior_to_completion_states
    %w(cart address delivery payment)
  end

  # All the states of a complete order but that shouldn't count towards the balance. Those that the
  # customer won't enjoy.
  def non_fulfilled_states
    %w(canceled returned)
  end
end
