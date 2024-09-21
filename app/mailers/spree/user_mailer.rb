# frozen_string_literal: true

# This mailer is configured to be the Devise mailer
# Some methods here override Devise::Mailer methods
module Spree
  class UserMailer < ApplicationMailer
    include I18nHelper

    # Overrides `Devise::Mailer.reset_password_instructions`
    def reset_password_instructions(user, token, _opts = {})
      @instance = Spree::Config[:site_name]
      @edit_password_reset_url = spree.
        edit_spree_user_password_url(reset_password_token: token)
      I18n.with_locale valid_locale(user) do
        subject = t('.subject', sitename: @instance)
        mail(to: user.email,
             subject:)
      end
    end

    # This is a OFN specific email, not from Devise::Mailer
    def signup_confirmation(user)
      @user = user
      @instance = Spree::Config[:site_name]
      I18n.with_locale valid_locale(@user) do
        subject = t('.subject', sitename: @instance)
        mail(to: user.email,
             subject:)
      end
    end

    # Overrides `Devise::Mailer.confirmation_instructions`
    def confirmation_instructions(user, token, _opts = {})
      @user = user
      @token = token
      @instance = Spree::Config[:site_name]
      @contact = ContentConfig.footer_email
      I18n.with_locale valid_locale(@user) do
        subject = t('.subject', sitename: @instance)
        mail(to: confirmation_email_address,
             subject:)
      end
    end

    private

    def confirmation_email_address
      @user.pending_reconfirmation? ? @user.unconfirmed_email : @user.email
    end
  end
end
