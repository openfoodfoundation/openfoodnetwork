# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # Inline stylesheets
  include Roadie::Rails::Automatic

  helper TermsAndConditionsHelper

  default from: -> { Spree::Config[:mails_from] }
  layout 'mailer'

  def money(amount)
    Spree::Money.new(amount).to_s
  end
  helper_method :money

  protected

  def roadie_options
    # This lets us specify assets using relative paths in email templates
    super.merge(url_options: { host: URI(main_app.root_url).host })
  end
end
