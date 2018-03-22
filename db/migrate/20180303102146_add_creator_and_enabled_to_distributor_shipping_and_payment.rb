class AddCreatorAndEnabledToDistributorShippingAndPayment < ActiveRecord::Migration
  def up
    add_column :distributors_shipping_methods, :creator_id, :integer
    add_column :distributors_shipping_methods, :enabled, :boolean, :default => true
    add_index :distributors_shipping_methods, [:creator_id], :name => "index_users_on_distributor_shipping"

    add_column :distributors_payment_methods, :creator_id, :integer
    add_column :distributors_payment_methods, :enabled, :boolean, :default => true
    add_index :distributors_payment_methods, [:creator_id], :name => "index_users_on_distributor_payments"
  end

  def down
    remove_index :distributors_shipping_methods, :name => "index_users_on_distributor_shipping"
    remove_column :distributors_shipping_methods, :creator_id
    remove_column :distributors_shipping_methods, :enabled

    remove_index :distributors_payment_methods, :name => "index_users_on_distributor_payments"
    remove_column :distributors_payment_methods, :creator_id
    remove_column :distributors_payment_methods, :enabled
  end
end
