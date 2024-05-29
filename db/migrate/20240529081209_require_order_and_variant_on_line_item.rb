class RequireOrderAndVariantOnLineItem < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_line_items, :order_id, false
    change_column_null :spree_line_items, :variant_id, false
  end
end
