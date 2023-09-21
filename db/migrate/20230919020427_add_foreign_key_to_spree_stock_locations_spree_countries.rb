class AddForeignKeyToSpreeStockLocationsSpreeCountries < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_locations, :spree_countries, column: :country_id
  end
end
