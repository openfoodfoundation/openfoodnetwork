class AddLockVersionToStockItems < ActiveRecord::Migration
  def change
    add_column :spree_stock_items, :lock_version, :integer, default: 0
  end
end
