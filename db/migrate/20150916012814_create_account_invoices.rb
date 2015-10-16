class CreateAccountInvoices < ActiveRecord::Migration
  def change
    create_table :account_invoices do |t|
      t.references :user, null: false
      t.references :order
      t.integer :year, null: false
      t.integer :month, null: false
      t.datetime :issued_at

      t.timestamps
    end
    add_index :account_invoices, :user_id
    add_index :account_invoices, :order_id

    add_foreign_key :account_invoices, :spree_orders, column: :order_id
    add_foreign_key :account_invoices, :spree_users, column: :user_id
  end
end
