class AddDeletedAtToSpreeStockItems < ActiveRecord::Migration[4.2]
  def up
    add_column :spree_stock_items, :deleted_at, :datetime
  end
end
