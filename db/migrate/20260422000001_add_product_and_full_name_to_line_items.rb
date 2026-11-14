# frozen_string_literal: true

class AddProductAndFullNameToLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_line_items, :product_and_full_name, :string
  end
end
