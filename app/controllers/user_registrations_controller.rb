# frozen_string_literal: true

require 'open_food_network/error_logger'
require "spree/core/controller_helpers/auth"
require "spree/core/controller_helpers/common"
require "spree/core/controller_helpers/order"

class UserRegistrationsController < Devise::RegistrationsController
  I18N_SCOPE = 'devise.user_registrations.spree_user'

  helper 'spree/base'

  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include I18nHelper

  skip_before_action :require_no_authentication

  before_action :set_checkout_redirect, only: :create
  before_action :set_locale

  # POST /resource/sign_up
  def create
    @user = build_resource(spree_user_params)
    @user.locale = I18n.locale.to_s
    unless resource.save
      return render_error(@user.errors)
    end

    session[:confirmation_return_url] = params[:return_url]
    associate_user

    respond_to do |format|
      format.js do
        render json: { email: @user.email }
      end
    end
  rescue StandardError => e
    OpenFoodNetwork::ErrorLogger.notify(e)
    render_error(message: I18n.t('unknown_error', scope: I18N_SCOPE))
  end

  private

  def spree_user_params
    return params[:spree_user] if params[:spree_user].blank?

    PermittedAttributes::User.new(params, :spree_user).call([:remember_me])
  end

  def render_error(errors = {})
    clean_up_passwords(resource)
    respond_to do |format|
      format.js do
        render json: errors, status: :unauthorized
      end
    end
  end
end
