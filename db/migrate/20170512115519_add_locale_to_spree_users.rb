class AddLocaleToSpreeUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :locale, :string, limit: 5
  end
end
