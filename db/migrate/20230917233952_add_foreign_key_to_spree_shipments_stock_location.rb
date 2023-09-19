class AddForeignKeyToSpreeShipmentsStockLocation < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipments, :spree_stock_locations, on_delete: :cascade
  end
end
