# frozen_string_literal: true

module OrderHelper
  def last_payment_method(order)
    OrderPaymentFinder.new(order).last_payment&.payment_method
  end
end
