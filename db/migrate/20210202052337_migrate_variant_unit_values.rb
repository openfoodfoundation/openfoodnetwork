class MigrateVariantUnitValues < ActiveRecord::Migration
  def up
    Spree::Variant.includes(:product).where(
      spree_products: { variant_unit: "items" },
      spree_variants: { unit_value: nil }
    ).find_each do |variant|
      variant.unit_value = 1
      variant.save
    end
    change_column_null :spree_variants, :unit_value, false, 1
    change_column_null :spree_variants, :weight, false, 0.0
  end

  def down
  end
end
