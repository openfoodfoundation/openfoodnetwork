class AddOrderCycleIdToProxyOrders < ActiveRecord::Migration
  def up
    add_column :proxy_orders, :order_cycle_id, :integer

    ProxyOrder.find_each do |proxy_order|
      order_cycle_id = proxy_order.order.order_cycle_id
      proxy_order.update_attribute(:order_cycle_id, order_cycle_id)
    end

    change_column :proxy_orders, :order_cycle_id, :integer, null: false
    add_index :proxy_orders, [:order_cycle_id, :standing_order_id], unique: true
    add_foreign_key :proxy_orders, :order_cycles
  end

  def down
    remove_foreign_key :proxy_orders, :order_cycles
    remove_index :proxy_orders, :order_cycle_id
    remove_column :proxy_orders, :order_cycle_id
  end
end
