module Spree
  class UserMailer < BaseMailer
    include I18nHelper

    def reset_password_instructions(user)
      recipient = user.respond_to?(:id) ? user : Spree.user_class.find(user)
      @edit_password_reset_url = spree.edit_spree_user_password_url(:reset_password_token => recipient.reset_password_token)

      mail(:to => recipient.email, :from => from_address,
          :subject => Spree::Config[:site_name] + ' ' + 
            I18n.t(:subject, :scope => [:devise, :mailer, :reset_password_instructions]))
    end

    def signup_confirmation(user)
      @user = user
      I18n.with_locale valid_locale(@user) do
        mail(to: user.email, from: from_address,
             subject: t(:welcome_to) + Spree::Config[:site_name])
      end
    end

    # Overriding `Spree::UserMailer.confirmation_instructions` which is
    # overriding `Devise::Mailer.confirmation_instructions`.
    def confirmation_instructions(user, _opts)
      @user = user
      @instance = Spree::Config[:site_name]
      @contact = ContentConfig.footer_email

      I18n.with_locale valid_locale(@user) do
        subject = t('spree.user_mailer.confirmation_instructions.subject')
        mail(to: confirmation_email_address,
             from: from_address,
             subject: subject)
      end
    end

    private

    def confirmation_email_address
      @user.pending_reconfirmation? ? @user.unconfirmed_email : @user.email
    end
  end
end
