class DropCompletedAtIndexOnSpreeOrders < ActiveRecord::Migration
  def change
    remove_index :spree_orders, :completed_at
  end
end
