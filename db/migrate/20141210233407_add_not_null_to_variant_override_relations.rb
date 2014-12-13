class AddNotNullToVariantOverrideRelations < ActiveRecord::Migration
  def change
    change_column :variant_overrides, :hub_id, :integer, null: false
    change_column :variant_overrides, :variant_id, :integer, null: false
  end
end
