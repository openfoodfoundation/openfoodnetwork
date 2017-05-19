Spree::BaseMailer.class_eval do
  # Inline stylesheets
  include Roadie::Rails::Automatic

  # Define layout
  layout 'mailer'

  protected

  def from_address
    Spree::MailMethod.current.andand.preferred_mails_from ||
      'test@example.com'
  end

  def roadie_options
    # This lets us specify assets using relative paths in email templates
    super.merge(url_options: {host: URI(spree.root_url).host })
  end
end
