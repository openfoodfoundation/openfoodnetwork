class AddTotalsToLineItem < ActiveRecord::Migration
  def up
    add_column :spree_line_items, :adjustment_total, :decimal,
               precision: 10, scale: 2, null: false, default: 0.0
    add_column :spree_line_items, :additional_tax_total, :decimal,
               precision: 10, scale: 2, null: false, default: 0.0
    add_column :spree_line_items, :included_tax_total, :decimal,
               precision: 10, scale: 2, null: false, default: 0.0

    Spree::LineItem.reset_column_information
  end

  def down
    remove_column :spree_line_items, :adjustment_total
    remove_column :spree_line_items, :additional_tax_total
    remove_column :spree_line_items, :included_tax_total
  end
end
