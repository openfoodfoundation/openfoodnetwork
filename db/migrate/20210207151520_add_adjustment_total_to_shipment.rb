class AddAdjustmentTotalToShipment < ActiveRecord::Migration
  def up
    add_column :spree_shipments, :adjustment_total, :decimal,
               precision: 10, scale: 2, null: false, default: 0.0
  end

  def down
    remove_column :spree_shipments, :adjustment_total
  end
end
