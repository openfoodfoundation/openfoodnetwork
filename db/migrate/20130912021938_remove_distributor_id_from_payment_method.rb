class RemoveDistributorIdFromPaymentMethod < ActiveRecord::Migration
  def up
    remove_column :spree_payment_methods, :distributor_id
  end

  def down
    add_column :spree_payment_methods, :distributor_id, :integer
    Spree::PaymentMethod.each do |pm|
      pm.distributor_id = pm.distributors.first.distributor_id if pm.distributors.first
    end
  end
end
