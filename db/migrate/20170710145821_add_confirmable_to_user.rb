class AddConfirmableToUser < ActiveRecord::Migration
  def up
    add_column :spree_users, :confirmation_token, :string
    add_column :spree_users, :confirmed_at, :datetime
    add_column :spree_users, :confirmation_sent_at, :datetime
    add_column :spree_users, :unconfirmed_email, :string
    add_index :spree_users, :confirmation_token, :unique => true

    # Set users to confirmed if they previously confirmed their email for an enterprise
    execute "UPDATE spree_users SET confirmed_at = enterprises.confirmed_at FROM enterprises WHERE spree_users.email = enterprises.email AND enterprises.confirmed_at IS NOT NULL"
  end

  def down
    remove_columns :spree_users, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end
end
