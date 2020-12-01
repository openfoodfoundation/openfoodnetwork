# frozen_string_literal: true

class ConfirmOrderJob < ActiveJob::Base
  def perform(order_id)
    Spree::OrderMailer.confirm_email_for_customer(order_id).deliver
    Spree::OrderMailer.confirm_email_for_shop(order_id).deliver
  end
end
