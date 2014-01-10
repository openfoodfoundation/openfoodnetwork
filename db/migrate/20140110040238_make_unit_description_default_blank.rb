class MakeUnitDescriptionDefaultBlank < ActiveRecord::Migration
  def up
    execute "UPDATE spree_variants SET unit_description='' WHERE unit_description IS NULL"
    change_column :spree_variants, :unit_description, :string, default: ''
  end

  def down
    change_column :spree_variants, :unit_description, :string, default: nil
  end
end
