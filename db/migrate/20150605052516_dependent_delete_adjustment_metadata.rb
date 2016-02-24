class DependentDeleteAdjustmentMetadata < ActiveRecord::Migration
  def up
    remove_foreign_key "adjustment_metadata", name: "adjustment_metadata_adjustment_id_fk"
    add_foreign_key "adjustment_metadata", "spree_adjustments", name: "adjustment_metadata_adjustment_id_fk", column: "adjustment_id", dependent: :delete
  end

  def down
    remove_foreign_key "adjustment_metadata", name: "adjustment_metadata_adjustment_id_fk"
    add_foreign_key "adjustment_metadata", "spree_adjustments", name: "adjustment_metadata_adjustment_id_fk", column: "adjustment_id"
  end
end
