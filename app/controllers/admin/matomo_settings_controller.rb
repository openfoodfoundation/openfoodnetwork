# frozen_string_literal: true

module Admin
  class MatomoSettingsController < Spree::Admin::BaseController
    def update
      Spree::Config.set(preferences_params.to_h)

      respond_to do |format|
        format.html {
          redirect_to main_app.edit_admin_matomo_settings_path
        }
      end
    end

    private

    def preferences_params
      params.require(:preferences).permit(
        :matomo_url,
        :matomo_site_id,
        :matomo_tag_manager_url,
      )
    end
  end
end
