class AddIndexOnShippingMethodsTaxCategory < ActiveRecord::Migration[5.0]
  def change
    add_index :spree_shipping_methods, :tax_category_id
  end
end
