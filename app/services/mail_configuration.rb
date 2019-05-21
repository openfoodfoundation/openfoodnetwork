# Configures Rails to use the specified mail configuration
#   by setting entries on the Spree Config
#   and initializing Spree:MailSettings that uses the Spree::Config.
class MailConfiguration
  # @param entries [Hash] Spree Config entries
  def self.entries=(entries)
    entries.each do |name, value|
      Spree::Config[name] = value
    end
    apply_mail_settings
  end

  private

  def self.apply_mail_settings
    Spree::Core::MailSettings.init
  end
end
