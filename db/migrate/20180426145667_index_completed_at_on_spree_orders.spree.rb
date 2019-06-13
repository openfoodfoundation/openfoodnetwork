# This migration comes from spree (originally 20130729214043)
class IndexCompletedAtOnSpreeOrders < ActiveRecord::Migration
  def change
    add_index :spree_orders, :completed_at
  end
end
