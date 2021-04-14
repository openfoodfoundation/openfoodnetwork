class AddLockVersionToStockItems < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_stock_items, :lock_version, :integer, default: 0
  end
end
