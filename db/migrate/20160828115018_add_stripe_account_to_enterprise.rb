class AddStripeAccountToEnterprise < ActiveRecord::Migration
  def change
    create_table :stripe_accounts do |t|
      t.string :stripe_user_id
      t.string :stripe_publishable_key
      t.timestamps
      t.belongs_to :enterprise, index: true
    end
  end
end
