class AddForeignKeyToInventoryItemsVariant < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :inventory_items, :spree_variants, on_delete: :cascade
  end
end
