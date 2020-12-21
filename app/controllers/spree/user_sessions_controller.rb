# frozen_string_literal: true

require "spree/core/controller_helpers/auth"
require "spree/core/controller_helpers/common"
require "spree/core/controller_helpers/order"
require "spree/core/controller_helpers/ssl"

module Spree
  class UserSessionsController < Devise::SessionsController
    helper 'spree/base'

    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::Common
    include Spree::Core::ControllerHelpers::Order
    include Spree::Core::ControllerHelpers::SSL

    ssl_required :new, :create, :destroy, :update
    ssl_allowed :login_bar

    before_action :set_checkout_redirect, only: :create
    after_action :ensure_valid_locale_persisted, only: :create

    def create
      authenticate_spree_user!

      if spree_user_signed_in?
        respond_to do |format|
          format.html {
            flash[:success] = t('devise.success.logged_in_succesfully')
            redirect_back_or_default(after_sign_in_path_for(spree_current_user))
          }
          format.js {
            render json: { email: spree_current_user.login }, status: :ok
          }
        end
      else
        respond_to do |format|
          format.html {
            flash.now[:error] = t('devise.failure.invalid')
            render :new
          }
          format.js {
            render json: { message: t('devise.failure.invalid') }, status: :unauthorized
          }
        end
      end
    end

    def destroy
      # Logout will clear session data including shopfront_redirect
      #   Here we store it before actually logging out so that the redirect works correctly
      @shopfront_redirect = session[:shopfront_redirect]

      super
    end

    private

    attr_reader :shopfront_redirect

    def accurate_title
      Spree.t(:login)
    end

    def redirect_back_or_default(default)
      redirect_to(session["spree_user_return_to"] || default)
      session["spree_user_return_to"] = nil
    end

    def ensure_valid_locale_persisted
      # When creating a new user session we have to wait until after a successful
      # login to be able to persist a selected locale on the current user

      UserLocaleSetter.new(spree_current_user, params[:locale], cookies).
        ensure_valid_locale_persisted
    end
  end
end
