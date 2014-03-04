class AddRequireShipAddressToShippingMethods < ActiveRecord::Migration
  def change
    add_column :spree_shipping_methods, :require_ship_address, :boolean, :default => true
    add_column :spree_shipping_methods, :description, :text
  end
end
