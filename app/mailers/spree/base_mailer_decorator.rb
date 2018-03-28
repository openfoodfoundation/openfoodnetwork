Spree::BaseMailer.class_eval do
  # Inline stylesheets
  include Roadie::Rails::Automatic

  # Define layout
  layout 'mailer'

  protected

  # This method copies the one defined in Spree's mailers. It should be removed
  # once in Spree v2.0 and Spree's BaseMailer class lands in our codebase.
  # Then, we'll be able to rely on its #from_address.
  def from_address
    Spree::MailMethod.current.preferred_mails_from
  end

  def roadie_options
    # This lets us specify assets using relative paths in email templates
    super.merge(url_options: {host: URI(spree.root_url).host })
  end
end
