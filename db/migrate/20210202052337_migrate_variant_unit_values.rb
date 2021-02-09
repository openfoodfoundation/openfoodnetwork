class MigrateVariantUnitValues < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute(<<-SQL)
      DELETE FROM "spree_variants" WHERE "product_id" IS NULL
    SQL

    ActiveRecord::Base.connection.execute(<<-SQL)
      UPDATE "spree_variants"
      SET "unit_value" = 1
      WHERE "unit_value" = 'NaN' OR "unit_value" IS NULL
    SQL


    ActiveRecord::Base.connection.execute(<<-SQL)
      UPDATE "spree_variants"
      SET "weight" = 0
      WHERE "weight" = 'NaN' OR "weight" IS NULL
    SQL

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
