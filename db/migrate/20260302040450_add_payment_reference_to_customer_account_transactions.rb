# frozen_string_literal: true

class AddPaymentReferenceToCustomerAccountTransactions < ActiveRecord::Migration[7.1]
  def change
    add_index :customer_account_transactions, :payment_id
    add_foreign_key :customer_account_transactions, :spree_payments, column: 'payment_id'
  end
end
