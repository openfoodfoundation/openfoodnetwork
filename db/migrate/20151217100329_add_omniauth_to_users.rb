class AddOmniauthToUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :provider, :string
    add_index :spree_users, :provider
    add_column :spree_users, :uid, :string
    add_index :spree_users, :uid
  end
end
