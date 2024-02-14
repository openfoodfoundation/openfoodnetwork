# frozen_string_literal: true

module Admin
  class OidcSettingsController < Spree::Admin::BaseController
    def index
      @account = spree_current_user.oidc_account
    end

    def destroy
      spree_current_user.oidc_account&.destroy
      redirect_to admin_oidc_settings_path
    end
  end
end
