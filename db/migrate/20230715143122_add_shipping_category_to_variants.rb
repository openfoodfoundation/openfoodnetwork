class AddShippingCategoryToVariants < ActiveRecord::Migration[7.0]
  def change
    add_reference :spree_variants, :shipping_category, foreign_key: { to_table: :spree_shipping_categories }
  end
end
