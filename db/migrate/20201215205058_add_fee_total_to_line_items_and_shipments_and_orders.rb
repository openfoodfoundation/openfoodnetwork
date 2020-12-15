class AddFeeTotalToLineItemsAndShipmentsAndOrders < ActiveRecord::Migration
  def change
    add_column :spree_line_items, :fee_total, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :spree_shipments, :fee_total, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :spree_orders, :fee_total, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
