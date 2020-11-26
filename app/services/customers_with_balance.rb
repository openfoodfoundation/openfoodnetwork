# frozen_string_literal: true

class CustomersWithBalance
  def initialize(enterprise_id)
    @enterprise_id = enterprise_id
  end

  def query
    Customer.of(enterprise_id).
      includes(:bill_address, :ship_address, user: :credit_cards).
      joins(left_join_non_cart_orders).
      group("customers.id").
      select("customers.*").
      select(outstanding_balance)
  end

  private

  attr_reader :enterprise_id

  # Arel doesn't support CASE statements until v7.1.0 so we'll have to wait with SQL literals
  # a little longer. See https://github.com/rails/arel/pull/400 for details.
  def outstanding_balance
    <<-SQL.strip_heredoc
       SUM(
         CASE WHEN state = 'canceled' THEN payment_total
              WHEN state IS NOT NULL THEN payment_total - total
         ELSE 0 END
       ) AS balance_value
    SQL
  end

  def left_join_non_cart_orders
    <<-SQL.strip_heredoc
      LEFT JOIN spree_orders ON spree_orders.customer_id = customers.id
        AND spree_orders.state != 'cart'
    SQL
  end
end
