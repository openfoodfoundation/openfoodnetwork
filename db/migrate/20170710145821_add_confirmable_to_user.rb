class AddConfirmableToUser < ActiveRecord::Migration
  def up
    add_column :spree_users, :confirmation_token, :string
    add_column :spree_users, :confirmed_at, :datetime
    add_column :spree_users, :confirmation_sent_at, :datetime
    add_column :spree_users, :unconfirmed_email, :string
    add_index :spree_users, :confirmation_token, :unique => true
  end

  def down
    remove_columns :spree_users, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end
end
