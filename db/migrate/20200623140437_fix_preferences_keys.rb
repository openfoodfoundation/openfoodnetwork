class FixPreferencesKeys < ActiveRecord::Migration
  def up
    new_preferences = Spree::Preference.where("key like '/%'")
    new_preferences.delete_all

    Spree::Preference.update_all("key = '/' || key")
  end

  def down
  end
end
