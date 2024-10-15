class AddVariantUnitToVariant < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_variants, :variant_unit_scale, :float
    add_column :spree_variants, :variant_unit_name, :string, limit: 255
  end
end
