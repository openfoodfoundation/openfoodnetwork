class AddForeignKeyToSpreeStockItemsSpreeStockLocations < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_items, :spree_stock_locations, column: :stock_location_id
  end
end
