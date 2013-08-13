class AddDistributorIdToPaymentMethod < ActiveRecord::Migration
  def change
    add_column :spree_payment_methods, :distributor_id, :integer
  end
end
