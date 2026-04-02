# frozen_string_literal: true

class AddCreatedByToCustomerAccountTransactions < ActiveRecord::Migration[7.1]
  def change
    add_reference :customer_account_transactions, :created_by,
                  null: true, foreign_key: { to_table: :spree_users }
  end
end
