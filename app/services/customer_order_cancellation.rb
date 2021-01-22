# frozen_string_literal: true

class CustomerOrderCancellation
  def initialize(order)
    @order = order
  end

  def call
    return unless order.cancel

    Spree::OrderMailer.cancel_email_for_shop(order).deliver_later
  end

  private

  attr_reader :order
end
