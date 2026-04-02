# frozen_string_literal: true

class CreateCustomerAccountTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :customer_account_transactions do |t|
      t.references :customer, null: false, foreign_key: { to_table: :customers }
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.string :currency
      t.string :description
      t.references :payment_method, null: false, foreign_key: { to_table: :spree_payment_methods }
      t.integer :payment_id

      t.timestamps
    end
  end
end
