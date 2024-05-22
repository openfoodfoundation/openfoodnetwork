class RequireStockItemAndQuantityOnStockMovement < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_stock_movements, :stock_item_id, false
    change_column_null :spree_stock_movements, :quantity, false
  end
end
