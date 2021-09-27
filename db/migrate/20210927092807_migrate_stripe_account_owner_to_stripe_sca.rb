class MigrateStripeAccountOwnerToStripeSca < ActiveRecord::Migration[6.1]
  def up
    replace_preferences_key("/spree/gateway/stripe_connect", "/spree/gateway/stripe_sca")
  end

  private

  def replace_preferences_key(from_pattern, to_pattern)
    updated_pref_key = "replace( pref.key, '" + from_pattern + "', '" + to_pattern + "')"
    execute(
      "UPDATE spree_preferences pref SET key = " + updated_pref_key + "
        WHERE pref.key like '" + from_pattern + "%'
          AND NOT EXISTS (SELECT 1 FROM spree_preferences existing_pref
                           WHERE existing_pref.key = " + updated_pref_key + ")"
    )
  end
end
