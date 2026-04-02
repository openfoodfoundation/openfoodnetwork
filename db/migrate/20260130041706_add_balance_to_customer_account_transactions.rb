# frozen_string_literal: true

class AddBalanceToCustomerAccountTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column(
      :customer_account_transactions, :balance, :decimal, precision: 10, scale: 2, default: 0
    )
  end
end
