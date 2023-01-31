class AddDimensionsToLineItems < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_line_items, :weight, :decimal, precision: 8, scale: 2
    add_column :spree_line_items, :height, :decimal, precision: 8, scale: 2
    add_column :spree_line_items, :width, :decimal, precision: 8, scale: 2
    add_column :spree_line_items, :depth, :decimal, precision: 8, scale: 2
  end
end
