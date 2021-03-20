class UpdateAdjustmentsIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :spree_adjustments, :adjustable_id

    add_index :spree_adjustments, [:adjustable_type, :adjustable_id]
    add_index :spree_adjustments, [:originator_type, :originator_id]
  end
end
