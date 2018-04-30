# This migration comes from spree (originally 20130226191231)
class AddStockLocationIdToSpreeShipments < ActiveRecord::Migration
  def change
    add_column :spree_shipments, :stock_location_id, :integer
  end
end
