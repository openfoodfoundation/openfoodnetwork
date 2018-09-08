# This migration comes from spree (originally 20130515180736)
class AddBackorderableDefaultToSpreeStockLocation < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :backorderable_default, :boolean, default: true
  end
end
