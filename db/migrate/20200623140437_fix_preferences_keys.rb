class FixPreferencesKeys < ActiveRecord::Migration
  def up
    unmigrated_preferences = Spree::Preference.exists?(['key NOT LIKE ?', '/%'])
    return unless unmigrated_preferences

    new_preferences = Spree::Preference.where("key LIKE '/%'")
    new_preferences.delete_all

    Spree::Preference.update_all("key = '/' || key")

    Rails.cache.clear
  end

  def down
  end
end
