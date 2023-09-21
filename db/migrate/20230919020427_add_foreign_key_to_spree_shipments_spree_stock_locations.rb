class AddForeignKeyToSpreeShipmentsSpreeStockLocations < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipments, :spree_stock_locations, column: :stock_location_id
  end
end
