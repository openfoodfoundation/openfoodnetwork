# frozen_string_literal: true

class AddProductNameToLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_line_items, :product_name, :string
  end
end
