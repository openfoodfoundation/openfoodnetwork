class AddIndexesToSpreeOrders < ActiveRecord::Migration
  def change
    add_index :spree_orders, :order_cycle_id
    add_index :spree_orders, :distributor_id
  end
end
