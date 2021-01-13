# frozen_string_literal: true

# Encapsulates the SQL statement that computes the balance of an order as a new column in the result
# set. This can then be reused chaining it with the ActiveRecord::Relation objects you pass in the
# constructor.
#
# Alternatively, you can get the SQL by calling #statement, which is suitable for more complex
# cases.
#
# See CompleteOrdersWithBalance or CustomersWithBalance as examples.
class OutstandingBalance
  def query
    <<-SQL.strip_heredoc
      CASE WHEN state IN #{non_fulfilled_states_group.to_sql} THEN payment_total
            WHEN state IS NOT NULL THEN payment_total - total
      ELSE 0 END
        AS balance_value
    SQL
  end

  private

  def non_fulfilled_states_group
    states = Spree::Order::NON_FULFILLED_STATES.map { |state| Arel::Nodes.build_quoted(state) }
    Arel::Nodes::Grouping.new(states)
  end
end
