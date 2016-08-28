class CreateStripeAccounts < ActiveRecord::Migration
  def change
    create_table :stripe_accounts do |t|
      t.string :stripe_user_id
      t.string :stripe_publishable_key
      t.timestamps
      t.belongs_to :enterprise
    end

    add_index :stripe_accounts, :enterprise_id, unique: true
  end
end
