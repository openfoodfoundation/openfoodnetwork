# frozen_string_literal: true

class ChangeFinalWeightVolumePrecisionInSpreeLineItems < ActiveRecord::Migration[7.1]
  def up
    change_column :spree_line_items, :final_weight_volume, :decimal, precision: 11, scale: 3
  end

  def down
    change_column :spree_line_items, :final_weight_volume, :decimal, precision: 10, scale: 2
  end
end
