# frozen_string_literal: true

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def openid_connect
    OidcAccount.link(spree_current_user, request.env["omniauth.auth"])

    redirect_to admin_oidc_settings_path
  end

  def failure
    error_message = request.env["omniauth.error"].to_s
    flash[:error] = t("devise.oidc.failure", error: error_message)

    super
  end
end
