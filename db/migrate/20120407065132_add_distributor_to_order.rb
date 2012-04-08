class AddDistributorToOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :distributor_id, :integer
  end
end
