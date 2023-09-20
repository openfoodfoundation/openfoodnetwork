class AddForeignKeyToSpreeStockMovementsSpreeStockItems < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_movements, :spree_stock_items, column: :stock_item_id
  end
end
