class AddOmniauthToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_users, :provider, :string
    add_column :spree_users, :uid, :string
  end
end
