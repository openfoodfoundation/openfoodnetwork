# frozen_string_literal: true

# Encapsulates the SQL statement that computes the balance of an order as a new column in the result
# set. This can then be reused chaining it with the ActiveRecord::Relation objects you pass in the
# constructor.
#
# Alternatively, you can get the SQL by calling #statement, which is suitable for more complex
# cases.
#
# See CompleteOrdersWithBalance or CustomersWithBalance as examples.
#
# Note this query object and `app/models/concerns/balance.rb` should implement the same behavior
# until we find a better way. If you change one, please, change the other too.
class OutstandingBalance
  # All the states of a finished order but that shouldn't count towards the balance (the customer
  # didn't get the order for whatever reason). Note it does not include complete
  FINALIZED_NON_SUCCESSFUL_STATES = %w(canceled returned).freeze

  # The relation must be an ActiveRecord::Relation object with `spree_orders` in the SQL statement
  # FROM for #statement to work.
  def initialize(relation = nil)
    @relation = relation
  end

  def query
    relation.select("#{statement} AS balance_value")
  end

  # Arel doesn't support CASE statements until v7.1.0 so we'll have to wait with SQL literals
  # a little longer. See https://github.com/rails/arel/pull/400 for details.
  def statement
    <<-SQL.strip_heredoc
      CASE WHEN "spree_orders"."state" IN #{non_fulfilled_states_group.to_sql} THEN "spree_orders"."payment_total"
           WHEN "spree_orders"."state" IS NOT NULL THEN "spree_orders"."payment_total" - "spree_orders"."total"
      ELSE 0 END
    SQL
  end

  private

  attr_reader :relation

  def non_fulfilled_states_group
    states = FINALIZED_NON_SUCCESSFUL_STATES.map { |state| Arel::Nodes.build_quoted(state) }
    Arel::Nodes::Grouping.new(states)
  end
end
