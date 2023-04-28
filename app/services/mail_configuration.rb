# frozen_string_literal: true

# Configures Rails to use the specified mail configuration
#   by setting entries on the Spree Config
#   and initializing Spree:MailSettings that uses the Spree::Config.
class MailConfiguration
  def self.apply!
    configuration.each do |name, value|
      Spree::Config[name] = value
    end
    apply_mail_settings
  end

  def self.configuration
    {
      mail_host: ENV.fetch('MAIL_HOST'),
      mail_domain: ENV.fetch('MAIL_DOMAIN'),
      mail_port: ENV.fetch('MAIL_PORT'),
      mail_auth_type: ENV.fetch('MAIL_AUTH_TYPE', 'login'),
      smtp_username: ENV.fetch('SMTP_USERNAME'),
      smtp_password: ENV.fetch('SMTP_PASSWORD'),
      secure_connection_type: ENV.fetch('MAIL_SECURE_CONNECTION', 'None'),
      mails_from: ENV.fetch('MAILS_FROM', "no-reply@#{ENV.fetch('MAIL_DOMAIN')}"),
      mail_bcc: ENV.fetch('MAIL_BCC', ''),
    }
  end

  def self.apply_mail_settings
    Spree::Core::MailSettings.init
  end
end
