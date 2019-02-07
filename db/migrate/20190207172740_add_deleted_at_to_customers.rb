class AddDeletedAtToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :deleted_at, :datetime
    add_index :customers, :deleted_at

    remove_foreign_key :spree_orders, :customers
  end
end
