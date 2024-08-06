class SetConnectedAppsEnabledIfAny < ActiveRecord::Migration[7.0]
  class ConnectedApp < ApplicationRecord
    scope :discover_regen, -> { where(type: "ConnectedApp") }
    scope :affiliate_sales_data, -> { where(type: "ConnectedApps::AffiliateSalesData") }
  end

  def up
    enabled = []
    enabled << "discover_regen" if ConnectedApp.discover_regen.any?
    enabled << "affiliate_sales_data" if ConnectedApp.affiliate_sales_data.any?

    Spree::Config.connected_apps_enabled = enabled.presence&.join(",")
  end
end
