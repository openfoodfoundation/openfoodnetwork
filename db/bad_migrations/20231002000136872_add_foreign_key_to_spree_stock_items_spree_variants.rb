# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_stock_items
# LEFT JOIN spree_variants
#   ON spree_stock_items.variant_id = spree_variants.id
# WHERE spree_variants.id IS NULL
#   AND spree_stock_items.variant_id IS NOT NULL


class AddForeignKeyToSpreeStockItemsSpreeVariants < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_stock_items, :spree_variants, column: :variant_id
  end
end
