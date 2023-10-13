# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_stock_items
# LEFT JOIN spree_stock_locations
#   ON spree_stock_items.stock_location_id = spree_stock_locations.id
# WHERE spree_stock_locations.id IS NULL
#   AND spree_stock_items.stock_location_id IS NOT NULL


class AddForeignKeyToSpreeStockItemsSpreeStockLocations < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_items, :spree_stock_locations, column: :stock_location_id
  end
end
