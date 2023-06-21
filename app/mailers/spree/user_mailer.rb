# frozen_string_literal: true

# This mailer is configured to be the Devise mailer
# Some methods here override Devise::Mailer methods
module Spree
  class UserMailer < ApplicationMailer
    include I18nHelper

    helper MailerHelper

    # Overrides `Devise::Mailer.reset_password_instructions`
    def reset_password_instructions(user, token, _opts = {})
      @edit_password_reset_url = spree.
        edit_spree_user_password_url(reset_password_token: token)
      subject = "#{Spree::Config[:site_name]} " \
                "#{I18n.t('spree.user_mailer.reset_password_instructions.subject')}"

      I18n.with_locale valid_locale(user) do
        mail(to: user.email, subject: subject)
      end
    end

    # This is a OFN specific email, not from Devise::Mailer
    def signup_confirmation(user)
      @user = user
      I18n.with_locale valid_locale(@user) do
        mail(to: user.email,
             subject: t(:welcome_to) + ' ' + Spree::Config[:site_name])
      end
    end

    # Overrides `Devise::Mailer.confirmation_instructions`
    def confirmation_instructions(user, token, _opts = {})
      @user = user
      @token = token
      @instance = Spree::Config[:site_name]
      @contact = ContentConfig.footer_email

      I18n.with_locale valid_locale(@user) do
        subject = t('spree.user_mailer.confirmation_instructions.subject')
        mail(to: confirmation_email_address,
             subject: subject)
      end
    end

    private

    def confirmation_email_address
      @user.pending_reconfirmation? ? @user.unconfirmed_email : @user.email
    end
  end
end
