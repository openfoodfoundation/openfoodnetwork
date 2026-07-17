# frozen_string_literal: true

class ChangeFinalWeightVolumeToScale113InSpreeLineItems < ActiveRecord::Migration[7.2]
  def up
    change_column :spree_line_items, :final_weight_volume, :decimal, precision: 11, scale: 3
  end

  def down
    change_column :spree_line_items, :final_weight_volume, :decimal, precision: 10, scale: 2
  end
end
