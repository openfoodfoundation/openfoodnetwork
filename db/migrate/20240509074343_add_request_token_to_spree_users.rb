class AddRequestTokenToSpreeUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_users, :request_token, :string
    add_index :spree_users, :request_token, unique: true
  end
end