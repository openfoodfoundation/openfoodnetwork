class DropOrdersShippingMethodId < ActiveRecord::Migration
  def up
    remove_column :spree_orders, :shipping_method_id
  end

  def down
    add_column :spree_orders, :shipping_method_id, :integer
  end
end
