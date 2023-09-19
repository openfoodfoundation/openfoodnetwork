class AddForeignKeyToStripeAccountsEnterprise < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :stripe_accounts, :enterprises, on_delete: :cascade
  end
end
