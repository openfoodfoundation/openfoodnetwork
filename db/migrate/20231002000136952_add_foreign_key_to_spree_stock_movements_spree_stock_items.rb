# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_stock_movements
# LEFT JOIN spree_stock_items
#   ON spree_stock_movements.stock_item_id = spree_stock_items.id
# WHERE spree_stock_items.id IS NULL
#   AND spree_stock_movements.stock_item_id IS NOT NULL


class AddForeignKeyToSpreeStockMovementsSpreeStockItems < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_movements, :spree_stock_items, column: :stock_item_id
  end
end
