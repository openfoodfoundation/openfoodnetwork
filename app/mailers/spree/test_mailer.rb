# frozen_string_literal: true

module Spree
  class TestMailer < ApplicationMailer
    def test_email(user)
      recipient = user.respond_to?(:id) ? user : Spree::User.find(user)
      subject = "#{Spree::Config[:site_name]} #{t('spree.test_mailer.test_email.subject')}"
      mail(to: recipient.email, subject: subject)
    end
  end
end
