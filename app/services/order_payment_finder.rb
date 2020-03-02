# frozen_string_literal: true

module OrderPaymentFinder
  def self.last_payment_method(order)
    # `max_by` avoids additional database queries when payments are loaded
    # already. There is usually only one payment and this shouldn't cause
    # any overhead compared to `order(:created_at).last`. Using `last`
    # without order is not deterministic.
    #
    # We are not using `updated_at` because all payments are touched when the
    # order is updated and then all payments have the same `updated_at` value.
    order.payments.max_by(&:created_at)&.payment_method
  end
end
