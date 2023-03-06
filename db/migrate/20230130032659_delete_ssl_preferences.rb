# frozen_string_literal: true

class DeleteSslPreferences < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      DELETE FROM spree_preferences
      WHERE key IN (
        '/spree/app_configuration/allow_ssl_in_production',
        '/spree/app_configuration/allow_ssl_in_staging'
      )
    SQL
  end
end
