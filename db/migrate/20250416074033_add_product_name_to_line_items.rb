class AddProductNameToLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_line_items, :product_name, :string, default: ""
  end
end
