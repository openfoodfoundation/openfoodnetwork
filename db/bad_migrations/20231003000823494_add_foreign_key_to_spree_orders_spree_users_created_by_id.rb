# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_orders
# LEFT JOIN spree_users
#   ON spree_orders.created_by_id = spree_users.id
# WHERE spree_users.id IS NULL
#   AND spree_orders.created_by_id IS NOT NULL


class AddForeignKeyToSpreeOrdersSpreeUsersCreatedById < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_orders, :spree_users, column: :created_by_id
  end
end
