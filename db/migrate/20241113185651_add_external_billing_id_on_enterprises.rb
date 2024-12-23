class AddExternalBillingIdOnEnterprises < ActiveRecord::Migration[7.0]
  def change
    add_column :enterprises, :external_billing_id, :string, limit: 128
  end
end
