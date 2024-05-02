class AddDeletedByToSpreeProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_products, :deleted_by_id, :integer, null: true
    add_foreign_key :spree_products, :spree_users, column: :deleted_by_id
  end
end
