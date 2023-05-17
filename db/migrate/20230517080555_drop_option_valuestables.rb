class DropOptionValuestables < ActiveRecord::Migration[7.0]
  def change
    drop_table :spree_option_values_variants
    drop_table :spree_option_values_line_items
    drop_table :spree_product_option_types
    drop_table :spree_option_values
    drop_table :spree_option_types
  end
end
