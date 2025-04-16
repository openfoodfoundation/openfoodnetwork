# frozen_string_literal: true

class AddVariantNameToLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_line_items, :variant_name, :string
  end
end
