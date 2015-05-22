class AddWeightToLineItems < ActiveRecord::Migration
  def change
    add_column :spree_line_items, :unit_value, :decimal, :precision => 8, :scale => 2
  end
end
