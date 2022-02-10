class ConvertStripeConnectToStripeSca < ActiveRecord::Migration[6.1]
  class SpreePreference < ActiveRecord::Base
    scope :leftover_from_payment_type, ->(class_name) {
      joins <<~SQL
         JOIN spree_payment_methods
           ON spree_preferences.key =
              CONCAT('/#{class_name.underscore}/enterprise_id/', spree_payment_methods.id)
          AND spree_payment_methods.type != '#{class_name}'
      SQL
    }
  end

  def up
    delete_outdated_spree_preferences
    upgrade_stripe_payment_methods
    update_payment_method_preferences
  end

  private

  # When changing the type of a payment method, we leave orphaned records in
  # the spree_preferences table. The key of the preference contains the type
  # of the payment method and therefore changing the type disconnects the
  # preference.
  #
  # Here we delete orphaned preferences first so that we don't have any
  # conflicts later when updating preferences alongside the connected
  # payment methods.
  def delete_outdated_spree_preferences
    outdated_keys =
      SpreePreference.leftover_from_payment_type("Spree::Gateway::StripeConnect").pluck(:key) +
      SpreePreference.leftover_from_payment_type("Spree::Gateway::StripeSCA").pluck(:key)

    SpreePreference.where(key: outdated_keys).delete_all

    # Spree preferences are cached and we want to avoid reading old values.
    # Danger: The cache may alter the given array in place. Make sure to
    # not use the `outdated_keys` variable after this call.
    Rails.cache.delete_multi(outdated_keys)
  end

  def upgrade_stripe_payment_methods
    execute <<~SQL
      UPDATE spree_payment_methods
        SET type = 'Spree::Gateway::StripeSCA'
      WHERE type = 'Spree::Gateway::StripeConnect'
    SQL
  end

  def update_payment_method_preferences
    execute <<~SQL
      UPDATE spree_preferences
         SET key = replace(key, 'stripe_connect', 'stripe_sca')
       WHERE key LIKE '/spree/gateway/stripe_connect/%'
    SQL
  end
end
