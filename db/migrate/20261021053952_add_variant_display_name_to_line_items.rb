# frozen_string_literal: true

class AddVariantDisplayNameToLineItems < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_line_items, :variant_display_name, :string
  end
end
