# Configures Rails to use the specified mail settings. It does so creating
# a Spree::MailMethod and applying its configuration.
class CreateMailMethod
  # Constructor
  #
  # @param attributes [Hash] MailMethod attributes
  def initialize(attributes)
    @attributes = attributes
  end

  def call
    persist_attributes
    initialize_mail_settings
  end

  private

  attr_reader :attributes

  # Updates the created mail method's attributes with the ones specified
  def persist_attributes
    mail_method.update_attributes(attributes)
  end

  # Creates a new Spree::MailMethod for the current environment
  def mail_method
    Spree::MailMethod.create(environment: attributes[:environment])
  end

  # Makes Spree apply the specified mail settings
  def initialize_mail_settings
    Spree::Core::MailSettings.init
  end
end
