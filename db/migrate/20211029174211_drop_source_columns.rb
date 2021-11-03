class DropSourceColumns < ActiveRecord::Migration[6.1]
  def change
    remove_column :spree_adjustments, :source_id, :integer
    remove_column :spree_adjustments, :source_type, :string
  end
end
