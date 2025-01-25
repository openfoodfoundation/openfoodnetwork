class SetDefaultStockLocationOnShipments < ActiveRecord::Migration[4.2]
  class SpreeStockLocation < ActiveRecord::Base
  end

  def up
    if Spree::Shipment.where('stock_location_id IS NULL').count > 0
      location = SpreeStockLocation.find_or_create_by(name: "default")
      Spree::Shipment.where('stock_location_id IS NULL').update_all(stock_location_id: location.id)
    end
  end
end
