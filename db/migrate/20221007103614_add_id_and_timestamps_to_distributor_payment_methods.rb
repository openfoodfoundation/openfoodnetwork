class AddIdAndTimestampsToDistributorPaymentMethods < ActiveRecord::Migration[6.1]
  def change
    add_column :distributors_payment_methods, :id, :primary_key
    add_column :distributors_payment_methods, :created_at, :datetime
    add_column :distributors_payment_methods, :updated_at, :datetime
  end
end
