class AddNotNullToVariantOverrideRelations < ActiveRecord::Migration
  def up
    change_column :variant_overrides, :hub_id, :integer, null: false
    change_column :variant_overrides, :variant_id, :integer, null: false
  end

  def down
    change_column :variant_overrides, :hub_id, :integer, null: true
    change_column :variant_overrides, :variant_id, :integer, null: true
  end
end
