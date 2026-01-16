# frozen_string_literal: true

module MailerHelper
  def order_reply_email(order)
    order.distributor.email_address.presence || order.distributor.contact.email
  end
end
