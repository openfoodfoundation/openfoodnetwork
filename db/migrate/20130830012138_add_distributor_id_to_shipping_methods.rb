class AddDistributorIdToShippingMethods < ActiveRecord::Migration
  def change
    add_column :spree_shipping_methods, :distributor_id, :integer
    add_index :spree_shipping_methods, :distributor_id
  end
end
