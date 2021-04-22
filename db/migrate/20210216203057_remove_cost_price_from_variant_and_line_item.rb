class RemoveCostPriceFromVariantAndLineItem < ActiveRecord::Migration[4.2]
  def up
    remove_column :spree_variants, :cost_price
    remove_column :spree_line_items, :cost_price
  end

  def down
    add_column :spree_variants, :cost_price, :decimal,
               precision: 8,  scale: 2
    add_column :spree_line_items, :cost_price, :integer,
               precision: 8,  scale: 2
  end
end
