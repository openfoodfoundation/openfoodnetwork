class AddForeignKeyToSpreeStockLocationsState < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_locations, :spree_states, on_delete: :cascade
  end
end
