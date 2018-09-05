class DropCarts < ActiveRecord::Migration
  def change
    remove_foreign_key :spree_orders, column: :cart_id
    remove_column :spree_orders, :cart_id
    drop_table :carts
  end
end
