class AddForeignKeyToSpreeShippingMethodCategoriesShippingCategory < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipping_method_categories, :spree_shipping_categories, on_delete: :cascade
  end
end
