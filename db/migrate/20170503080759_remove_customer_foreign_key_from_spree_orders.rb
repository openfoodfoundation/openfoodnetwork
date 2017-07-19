class RemoveCustomerForeignKeyFromSpreeOrders < ActiveRecord::Migration
  def up
    remove_foreign_key :spree_orders, :customers
  end

  def down
    add_foreign_key :spree_orders, :customers, column: :customer_id
  end
end
