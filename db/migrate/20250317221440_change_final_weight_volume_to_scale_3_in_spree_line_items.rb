# frozen_string_literal: true

class ChangeFinalWeightVolumeToScale3InSpreeLineItems < ActiveRecord::Migration[7.0]
  def up
    change_column :spree_line_items, :final_weight_volume, :decimal, precision: 10, scale: 3
  end

  def down
    change_column :spree_line_items, :final_weight_volume, :decimal, precision: 10, scale: 2
  end
end
