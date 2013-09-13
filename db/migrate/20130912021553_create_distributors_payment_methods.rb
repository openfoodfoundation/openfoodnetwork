class CreateDistributorsPaymentMethods < ActiveRecord::Migration
  def up
    create_table :distributors_payment_methods, :id => false do |t|
      t.references :distributor
      t.references :payment_method
    end
    Spree::PaymentMethod.all.each do |pm|
      pm.distributors << pm.distributor if pm.distributor_id
    end
  end

  def down
    drop_table :distributors_payment_methods
  end
end
