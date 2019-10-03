# Ensures variant.unit_value and variant.unit_description are not null at the same time for a given variant
class AddVariantUnitValueUnitDescriptionNotNullConstraint < ActiveRecord::Migration
  def up
    execute "ALTER TABLE spree_variants ADD CONSTRAINT unit_value_or_unit_desc CHECK (unit_value is not null or unit_description is not null);"
  end

  def down
    execute "ALTER TABLE spree_variants DROP CONSTRAINT unit_value_or_unit_desc;"
  end
end
