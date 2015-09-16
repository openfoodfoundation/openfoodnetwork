class UpdatePrecisionOnLineItemFinalWeightVolume < ActiveRecord::Migration
  def up
    change_column :spree_line_items, :final_weight_volume, :decimal, :precision => 10, :scale => 2
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end


