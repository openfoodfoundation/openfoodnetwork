require 'open_food_network/error_logger'

class UserRegistrationsController < Spree::UserRegistrationsController
  I18N_SCOPE = 'devise.user_registrations.spree_user'.freeze

  before_filter :set_checkout_redirect, only: :create

  # POST /resource/sign_up
  def create
    @user = build_resource(params[:spree_user])
    if resource.save
      session[:spree_user_signup] = true
      session[:confirmation_return_url] = params[:return_url]
      associate_user

      respond_to do |format|
        format.html do
          set_flash_message(:success, :signed_up_but_unconfirmed)
          redirect_to after_sign_in_path_for(@user)
        end
        format.js do
          render json: { email: @user.email }
        end
      end
    else
      render_error(@user.errors)
    end
  rescue StandardError => error
    OpenFoodNetwork::ErrorLogger.notify(error)
    render_error(message: I18n.t('unknown_error', scope: I18N_SCOPE))
  end

  private

  def render_error(errors = {})
    clean_up_passwords(resource)
    respond_to do |format|
      format.html do
        render :new
      end
      format.js do
        render json: errors, status: :unauthorized
      end
    end
  end
end
