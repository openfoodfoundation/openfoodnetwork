# frozen_string_literal: true

require "spree/core/controller_helpers/auth"
require "spree/core/controller_helpers/common"
require "spree/core/controller_helpers/order"

module Spree
  class UserSessionsController < Devise::SessionsController
    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::Common
    include Spree::Core::ControllerHelpers::Order

    helper 'spree/base'

    prepend_before_action :handle_unconfirmed_email
    before_action :set_checkout_redirect, only: :create
    after_action :ensure_valid_locale_persisted, only: :create
    skip_before_action :check_disabled_user

    def create
      authenticate_spree_user!

      if spree_user_signed_in?
        flash[:success] = t('devise.success.logged_in_succesfully')

        redirect_to return_url_or_default(after_sign_in_path_for(spree_current_user))
      else
        message = t('devise.failure.invalid')
        render turbo_stream: turbo_stream.update(
          'login-feedback', partial: 'layouts/alert', locals: { message:, type: 'alert' }
        ), status: :unprocessable_entity
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

    def handle_unconfirmed_email
      render_unconfirmed_response if email_unconfirmed?
    end

    def email_unconfirmed?
      Spree::User.where(email: params.dig(:spree_user, :email), confirmed_at: nil).exists?
    end

    def render_unconfirmed_response
      message = t(:email_unconfirmed)

      render turbo_stream: turbo_stream.update(
        'login-feedback',
        partial: 'layouts/alert', locals: { type: "alert", message:, unconfirmed: true,
                                            tab: "login", email: params.dig(:spree_user, :email) }
      ), status: :unprocessable_entity
    end

    def ensure_valid_locale_persisted
      # When creating a new user session we have to wait until after a successful
      # login to be able to persist a selected locale on the current user

      UserLocaleSetter.new(spree_current_user, params[:locale], cookies).
        ensure_valid_locale_persisted
    end
  end
end
