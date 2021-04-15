class AddUnitValueConstraint < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE spree_variants SET unit_value = 1 WHERE unit_value <= 0"
    execute "ALTER TABLE spree_variants ADD CONSTRAINT positive_unit_value CHECK (unit_value > 0)"
  end

  def down
    execute "ALTER TABLE spree_variants DROP CONSTRAINT positive_unit_value"
  end
end
