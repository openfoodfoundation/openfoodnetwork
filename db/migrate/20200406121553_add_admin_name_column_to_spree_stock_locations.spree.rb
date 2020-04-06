# This migration comes from spree (originally 20130809164330)
class AddAdminNameColumnToSpreeStockLocations < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :admin_name, :string
  end
end
