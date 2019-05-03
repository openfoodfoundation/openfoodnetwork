# This migration comes from spree (originally 20130326175857)
class AddStockLocationToRma < ActiveRecord::Migration
  def change
    add_column :spree_return_authorizations, :stock_location_id, :integer
  end
end
