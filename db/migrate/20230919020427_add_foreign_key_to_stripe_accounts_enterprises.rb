class AddForeignKeyToStripeAccountsEnterprises < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :stripe_accounts, :enterprises, column: :enterprise_id
  end
end
