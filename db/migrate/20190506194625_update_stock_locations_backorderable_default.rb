class UpdateStockLocationsBackorderableDefault < ActiveRecord::Migration
  def change
    Spree::StockLocation.update_all(backorderable_default: false)
  end
end
