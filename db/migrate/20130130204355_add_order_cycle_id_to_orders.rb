class AddOrderCycleIdToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :order_cycle_id, :integer
  end
end
