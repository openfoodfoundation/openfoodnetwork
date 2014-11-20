Spree::BaseMailer.class_eval do
  # Inline stylesheets
  include Roadie::Rails::Automatic

  # Define layout
  layout 'mailer'
  helper Spree::MailerHelper

  protected
  def roadie_options
    binding.pry
    super.merge(url_options: {host: URI(spree.root_url).host })
  end
end