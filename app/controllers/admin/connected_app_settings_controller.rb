# frozen_string_literal: true

module Admin
  class ConnectedAppSettingsController < Spree::Admin::BaseController
    def update
      Spree::Config.set(connected_apps_enabled:)

      respond_to do |format|
        format.html {
          redirect_to main_app.edit_admin_connected_app_settings_path
        }
      end
    end

    private

    def connected_apps_enabled
      params.require(:preferences).require(:connected_apps_enabled).join(",")
    end
  end
end
