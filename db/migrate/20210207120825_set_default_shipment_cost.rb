class SetDefaultShipmentCost < ActiveRecord::Migration
  def up
    change_column_null :spree_shipments, :cost, false, 0.0
    change_column_default :spree_shipments, :cost, 0.0
  end

  def down
    change_column_null :spree_shipments, :cost, true
    change_column_default :spree_shipments, :cost, nil
  end
end
