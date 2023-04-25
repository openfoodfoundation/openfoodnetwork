# frozen_string_literal: true

class SubscriptionMailerPreview < ActionMailer::Preview
  def confirmation_email
    SubscriptionMailer.confirmation_email(Spree::Order.complete.last)
  end
end
