class RequireVariantAndStockLocationOnStockItem < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_stock_items, :stock_location_id, false
    change_column_null :spree_stock_items, :variant_id, false
  end
end
