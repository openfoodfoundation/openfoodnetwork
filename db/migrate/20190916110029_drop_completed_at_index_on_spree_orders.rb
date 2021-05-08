class DropCompletedAtIndexOnSpreeOrders < ActiveRecord::Migration[4.2]
  def change
    remove_index :spree_orders, :completed_at
  end
end
