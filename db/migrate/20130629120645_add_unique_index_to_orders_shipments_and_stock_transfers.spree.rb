# This migration comes from spree (originally 20130628022817)
class AddUniqueIndexToOrdersShipmentsAndStockTransfers < ActiveRecord::Migration
  def add
    add_index "spree_orders", ["number"], :name => "number_idx_unique", :unique => true
    add_index "spree_shipments", ["number"], :name => "number_idx_unique", :unique => true
  end
end
