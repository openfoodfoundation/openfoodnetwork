# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_shipments
# LEFT JOIN spree_stock_locations
#   ON spree_shipments.stock_location_id = spree_stock_locations.id
# WHERE spree_stock_locations.id IS NULL
#   AND spree_shipments.stock_location_id IS NOT NULL


class AddForeignKeyToSpreeShipmentsSpreeStockLocations < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipments, :spree_stock_locations, column: :stock_location_id
  end
end
