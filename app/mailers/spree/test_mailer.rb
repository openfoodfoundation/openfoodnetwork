# frozen_string_literal: true

module Spree
  class TestMailer < ApplicationMailer
    def test_email(user)
      recipient = user.respond_to?(:id) ? user : Spree::User.find(user)
      subject = t('.subject', sitename: Spree::Config[:site_name])
      mail(to: recipient.email, subject:)
    end
  end
end
