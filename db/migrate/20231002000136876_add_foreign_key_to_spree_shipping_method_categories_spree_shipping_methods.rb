# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM spree_shipping_method_categories
# LEFT JOIN spree_shipping_methods
#   ON spree_shipping_method_categories.shipping_method_id = spree_shipping_methods.id
# WHERE spree_shipping_methods.id IS NULL
#   AND spree_shipping_method_categories.shipping_method_id IS NOT NULL


class AddForeignKeyToSpreeShippingMethodCategoriesSpreeShippingMethods < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipping_method_categories, :spree_shipping_methods, column: :shipping_method_id
  end
end
