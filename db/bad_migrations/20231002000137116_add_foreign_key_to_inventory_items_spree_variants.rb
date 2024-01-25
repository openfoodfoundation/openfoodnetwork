# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM inventory_items
# LEFT JOIN spree_variants
#   ON inventory_items.variant_id = spree_variants.id
# WHERE spree_variants.id IS NULL
#   AND inventory_items.variant_id IS NOT NULL


class AddForeignKeyToInventoryItemsSpreeVariants < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :inventory_items, :spree_variants, column: :variant_id
  end
end
