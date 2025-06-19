# frozen_string_literal: true

class AddNotNullToProductNameInLineItems < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_line_items, :product_name, false
  end
end
