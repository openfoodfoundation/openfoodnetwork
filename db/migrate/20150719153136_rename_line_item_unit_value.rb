class RenameLineItemUnitValue < ActiveRecord::Migration
  def change
    rename_column :spree_line_items, :unit_value, :final_weight_volume
  end
end
