class AddIndexesToSpreeOrders < ActiveRecord::Migration[4.2]
  def change
    add_index :spree_orders, :order_cycle_id
    add_index :spree_orders, :distributor_id
  end
end
