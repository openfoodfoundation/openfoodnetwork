# frozen_string_literal: true

class OrderMailerPreview < ActionMailer::Preview
  def confirm_email_for_customer
    order = Spree::Order.complete.last
    order.assign_attributes(note: "")
    Spree::OrderMailer.confirm_email_for_customer(order)
  end

  def confirm_email_for_customer_with_note
    order = Spree::Order.complete.last
    order.assign_attributes(note: "We substituted the organic apples with pears from a local farm.")
    Spree::OrderMailer.confirm_email_for_customer(order)
  end

  def confirm_email_for_shop_with_note
    order = Spree::Order.complete.last
    order.assign_attributes(note: "We substituted the organic apples with pears from a local farm.")
    Spree::OrderMailer.confirm_email_for_shop(order)
  end
end
