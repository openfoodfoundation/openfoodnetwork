# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_shipping_method_categories
# LEFT JOIN spree_shipping_categories
#   ON spree_shipping_method_categories.shipping_category_id = spree_shipping_categories.id
# WHERE spree_shipping_categories.id IS NULL
#   AND spree_shipping_method_categories.shipping_category_id IS NOT NULL


class AddForeignKeyToSpreeShippingMethodCategoriesSpreeShippingCategories < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipping_method_categories, :spree_shipping_categories, column: :shipping_category_id
  end
end
