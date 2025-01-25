# frozen_string_literal: true

class AllowNullStockLocationIdOnSpreeStockItems < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_stock_items, :stock_location_id, true
  end
end
