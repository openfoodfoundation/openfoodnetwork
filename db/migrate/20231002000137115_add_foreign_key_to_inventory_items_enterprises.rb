# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM inventory_items
# LEFT JOIN enterprises
#   ON inventory_items.enterprise_id = enterprises.id
# WHERE enterprises.id IS NULL
#   AND inventory_items.enterprise_id IS NOT NULL


class AddForeignKeyToInventoryItemsEnterprises < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :inventory_items, :enterprises, column: :enterprise_id
  end
end
