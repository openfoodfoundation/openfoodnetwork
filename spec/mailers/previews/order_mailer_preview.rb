# frozen_string_literal: true

class OrderMailerPreview < ActionMailer::Preview
  def confirm_email_for_customer
    Spree::OrderMailer.confirm_email_for_customer(Spree::Order.complete.last)
  end
end
