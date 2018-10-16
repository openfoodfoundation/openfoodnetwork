class RemoveShippingMethodNameFromSpreeLineItems < ActiveRecord::Migration
  def up
    remove_column :spree_line_items, :shipping_method_name
  end

  def down
    add_column :spree_line_items, :shipping_method_name, :string
  end
end
