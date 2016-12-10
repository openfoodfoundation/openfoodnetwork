class RenameStandingOrderOrdersToProxyOrders < ActiveRecord::Migration
  def change
    remove_index :standing_order_orders, :order_id
    remove_index :standing_order_orders, :standing_order_id
    rename_table :standing_order_orders, :proxy_orders
    add_index :proxy_orders, :order_id, unique: true
    add_index :proxy_orders, :standing_order_id
  end
end
