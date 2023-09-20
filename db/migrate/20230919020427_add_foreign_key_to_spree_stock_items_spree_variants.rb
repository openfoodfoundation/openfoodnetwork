class AddForeignKeyToSpreeStockItemsSpreeVariants < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_items, :spree_variants, column: :variant_id
  end
end
