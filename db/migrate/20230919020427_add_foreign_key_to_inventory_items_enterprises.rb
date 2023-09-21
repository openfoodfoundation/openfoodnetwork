class AddForeignKeyToInventoryItemsEnterprises < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :inventory_items, :enterprises, column: :enterprise_id, on_delete: :cascade
  end
end
