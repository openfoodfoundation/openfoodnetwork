class AddForeignKeyToSpreeStockLocationsSpreeStates < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_locations, :spree_states, column: :state_id
  end
end
