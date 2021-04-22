class IncreaseCharactersOfLocaleInSpreeUsers < ActiveRecord::Migration[4.2]
  def up
    change_column :spree_users, :locale, :string, limit: 6
  end

  def down
    change_column :spree_users, :locale, :string, limit: 5
  end
end
