class PopulateLineItemUnitValue < ActiveRecord::Migration
  def up
    execute "UPDATE spree_line_items SET unit_value = spree_variants.unit_value FROM spree_variants WHERE spree_line_items.variant_id = spree_variants.id"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
