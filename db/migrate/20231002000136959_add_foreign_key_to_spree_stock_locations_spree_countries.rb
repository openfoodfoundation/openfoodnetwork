# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_stock_locations
# LEFT JOIN spree_countries
#   ON spree_stock_locations.country_id = spree_countries.id
# WHERE spree_countries.id IS NULL
#   AND spree_stock_locations.country_id IS NOT NULL


class AddForeignKeyToSpreeStockLocationsSpreeCountries < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_locations, :spree_countries, column: :country_id
  end
end
