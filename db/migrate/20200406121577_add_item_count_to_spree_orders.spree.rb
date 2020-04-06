# This migration comes from spree (originally 20131218054603)
class AddItemCountToSpreeOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :item_count, :integer, :default => 0
  end
end
