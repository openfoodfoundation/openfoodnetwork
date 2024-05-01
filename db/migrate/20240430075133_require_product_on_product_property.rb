class RequireProductOnProductProperty < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_product_properties, :product_id, false
  end
end
