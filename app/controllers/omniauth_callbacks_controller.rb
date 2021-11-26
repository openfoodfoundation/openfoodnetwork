class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_action :check_authorization, only: %i[openid_connect]

  def openid_connect
    spree_current_user.link_from_omniauth(request.env["omniauth.auth"])

    redirect_to Spree::Core::Engine.routes.url_helpers.admin_dfc_settings
  end

  def failure
    error_message = request.env["omniauth.error"].to_s
    flash[:error] = t("devise.oidc.failure", error: error_message)
    super
  end

  private

  def check_authorization
    return if spree_user_signed_in?

    redirect_to root_url
  end
end
