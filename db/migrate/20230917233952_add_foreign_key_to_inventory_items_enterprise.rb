class AddForeignKeyToInventoryItemsEnterprise < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :inventory_items, :enterprises, on_delete: :cascade
  end
end
