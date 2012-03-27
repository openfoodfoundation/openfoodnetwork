class CreateSkrillTransactions < ActiveRecord::Migration
  def change
    create_table :spree_skrill_transactions do |t|
      t.string :email
      t.float :amount
      t.string :currency
      t.integer :transaction_id
      t.integer :customer_id
      t.string :payment_type
      t.timestamps
    end
  end
end

