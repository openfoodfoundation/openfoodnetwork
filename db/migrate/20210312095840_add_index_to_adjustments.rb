class AddIndexToAdjustments < ActiveRecord::Migration
  def change
    add_index :spree_adjustments, :order_id
  end
end
