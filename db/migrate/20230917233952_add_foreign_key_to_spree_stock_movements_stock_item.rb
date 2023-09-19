class AddForeignKeyToSpreeStockMovementsStockItem < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_movements, :spree_stock_items, on_delete: :cascade
  end
end
