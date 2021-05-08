class SetDefaultStockLocationOnShipments < ActiveRecord::Migration[4.2]
  def up
    if Spree::Shipment.where('stock_location_id IS NULL').count > 0
      location = DefaultStockLocation.find_or_create
      Spree::Shipment.where('stock_location_id IS NULL').update_all(stock_location_id: location.id)
    end
  end
end
