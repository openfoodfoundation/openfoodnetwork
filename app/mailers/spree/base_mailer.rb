# frozen_string_literal: true

module Spree
  class BaseMailer < ActionMailer::Base
    # Inline stylesheets
    include Roadie::Rails::Automatic

    helper TermsAndConditionsHelper

    layout 'mailer'

    def from_address
      Spree::Config[:mails_from]
    end

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
end
