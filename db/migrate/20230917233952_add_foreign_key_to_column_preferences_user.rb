class AddForeignKeyToColumnPreferencesUser < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :column_preferences, :spree_users, on_delete: :cascade
  end
end
