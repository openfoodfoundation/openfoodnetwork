class AddNameToSpreeUser < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_users, :name, :string
  end
end
