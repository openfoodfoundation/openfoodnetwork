class UpdateSpreeLineItemFinalWeightVolume < ActiveRecord::Migration
  def up
    execute "UPDATE spree_line_items SET final_weight_volume = final_weight_volume * quantity"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
