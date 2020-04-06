# This migration comes from spree (originally 20130611185927)
class AddUserIdIndexToSpreeOrders < ActiveRecord::Migration
  def change
    add_index :spree_orders, :user_id
  end
end
