class SetupProductUnitsAndValues < ActiveRecord::Migration
  def change
    change_table :spree_products do |t|
      t.string :variant_unit
      t.float :variant_unit_scale
      t.string :variant_unit_name
    end

    change_table :spree_variants do |t|
      t.float :unit_value
      t.string :unit_description
    end
  end
end
