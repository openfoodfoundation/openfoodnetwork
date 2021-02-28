class AddShipmentTotalToOrders < ActiveRecord::Migration
  def up
    add_column :spree_orders, :shipment_total, :decimal,
               precision: 10, scale: 2, null: false, default: 0.0
  end

  def down
    remove_column :spree_orders, :shipment_total
  end
end
