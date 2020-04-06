# This migration comes from spree (originally 20140203161722)
class AddApproverIdAndApprovedAtToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :approver_id, :integer
    add_column :spree_orders, :approved_at, :datetime
  end
end
