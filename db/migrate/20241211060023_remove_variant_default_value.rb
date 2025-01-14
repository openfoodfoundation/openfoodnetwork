class RemoveVariantDefaultValue < ActiveRecord::Migration[7.0]
  def up
    change_table :spree_variants do |t|
      t.change_null :weight, true
      t.change_default :weight, nil
      t.change_null :unit_value, true
      t.change_default :unit_value, nil
    end
    execute <<-SQL
        ALTER TABLE spree_variants
          DROP CONSTRAINT IF EXISTS check_unit_value_for_nan;
        ALTER TABLE spree_variants
          DROP CONSTRAINT IF EXISTS check_weight_for_nan;
      SQL
  end

  def down
    change_table :spree_variants do |t|
      t.change_null :weight, false
      t.change_default :weight, "0.0"
      t.change_null :unit_value, false
      t.change_default :unit_value, "1.0"
      t.check_constraint("unit_value <> 'NaN'::double precision", name: "check_unit_value_for_nan")
      t.check_constraint("weight <> 'NaN'::numeric", name: "check_weight_for_nan")
    end
  end
end
