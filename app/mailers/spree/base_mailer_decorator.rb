Spree::BaseMailer.class_eval do
  # Inline stylesheets
  include Roadie::Rails::Automatic

  # Define layout
  layout 'mailer'
  helper Spree::MailerHelper
end