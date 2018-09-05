module Admin
  class MatomoSettingsController < Spree::Admin::BaseController
    def update
      Spree::Config.set(params[:preferences])

      respond_to do |format|
        format.html {
          redirect_to main_app.edit_admin_matomo_settings_path
        }
      end
    end
  end
end
