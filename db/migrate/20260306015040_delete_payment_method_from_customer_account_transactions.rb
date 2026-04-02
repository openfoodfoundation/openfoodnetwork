# frozen_string_literal: true

class DeletePaymentMethodFromCustomerAccountTransactions < ActiveRecord::Migration[7.1]
  def change
    remove_reference :customer_account_transactions,
                     :payment_method, index: true, foreign_key: { to_table: :spree_payment_methods }
  end
end
