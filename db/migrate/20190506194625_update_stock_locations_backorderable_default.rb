class UpdateStockLocationsBackorderableDefault < ActiveRecord::Migration[4.2]
  def change
    Spree::StockLocation.update_all(backorderable_default: false)
  end
end
