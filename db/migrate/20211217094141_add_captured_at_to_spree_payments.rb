class AddCapturedAtToSpreePayments < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_payments, :captured_at, :datetime
  end
end
