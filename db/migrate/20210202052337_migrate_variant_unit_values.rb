class MigrateVariantUnitValues < ActiveRecord::Migration
  def up
    Spree::Variant.where(product_id: nil).destroy_all
    Spree::Variant.where(unit_value: [nil, Float::NAN]).find_each do |variant|
      variant.unit_value = 1
      variant.save
    end
    Spree::Variant.where(weight: [nil, Float::NAN]).find_each do |variant|
      variant.weight = 0
      variant.save
    end
    change_column_null :spree_variants, :unit_value, false, 1
    change_column_null :spree_variants, :weight, false, 0.0
    change_column_default :spree_variants, :unit_value, 1
    change_column_default :spree_variants, :weight, 0.0
    execute "ALTER TABLE spree_variants ADD CONSTRAINT check_unit_value_for_nan CHECK (unit_value <> 'NaN')"
    execute "ALTER TABLE spree_variants ADD CONSTRAINT check_weight_for_nan CHECK (weight <> 'NaN')"
  end

  def down
    change_column_null :spree_variants, :unit_value, true
    change_column_null :spree_variants, :weight, true
    change_column_default :spree_variants, :unit_value, nil
    change_column_default :spree_variants, :weight, nil
    execute "ALTER TABLE spree_variants DROP CONSTRAINT check_unit_value_for_nan"
    execute "ALTER TABLE spree_variants DROP CONSTRAINT check_weight_for_nan"
  end
end
