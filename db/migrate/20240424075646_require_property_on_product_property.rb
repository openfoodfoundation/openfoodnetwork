# frozen_string_literal: true

class RequirePropertyOnProductProperty < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_product_properties, :property_id, false
  end
end
