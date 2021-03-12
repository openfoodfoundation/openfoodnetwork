class AddIndexToAdjustments < ActiveRecord::Migration[5.0]
  def change
    add_index :spree_adjustments, :order_id
  end
end
