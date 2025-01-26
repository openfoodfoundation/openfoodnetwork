# frozen_string_literal: true

class DeleteCheckoutZoneAndCurrencyPreferences < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      DELETE FROM spree_preferences
      WHERE key IN (
        '/spree/app_configuration/checkout_zone',
        '/spree/app_configuration/currency'
      )
    SQL
  end
end
