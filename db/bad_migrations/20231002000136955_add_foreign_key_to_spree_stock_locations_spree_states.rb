# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_stock_locations
# LEFT JOIN spree_states
#   ON spree_stock_locations.state_id = spree_states.id
# WHERE spree_states.id IS NULL
#   AND spree_stock_locations.state_id IS NOT NULL


class AddForeignKeyToSpreeStockLocationsSpreeStates < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_locations, :spree_states, column: :state_id
  end
end
