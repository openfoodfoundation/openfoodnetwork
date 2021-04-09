# For some unkonwn reason, after removing Spree as a dependency, some spree calculators appeared on live DBs
# Here we repeat the migration
class RepeatMoveCalculatorsPreferencesOutsideSpreeNamespace < ActiveRecord::Migration[4.2]
  def up
    replace_preferences_key("/spree/calculator", "/calculator")
  end

  def down
    replace_preferences_key("/calculator", "/spree/calculator")
  end

  private

  def replace_preferences_key(from_pattern, to_pattern)
    updated_pref_key = "replace( pref.key, '" + from_pattern + "', '" + to_pattern + "')"
    Spree::Preference.connection.execute(
      "UPDATE spree_preferences pref SET key = " + updated_pref_key + "
        WHERE pref.key like '" + from_pattern + "%'
          AND NOT EXISTS (SELECT 1 FROM spree_preferences existing_pref
                           WHERE existing_pref.key = " + updated_pref_key + ")"
    )

    Rails.cache.clear
  end
end
