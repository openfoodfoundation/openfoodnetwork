# frozen_string_literal: true

module Orders
  class FindPaymentService
    def initialize(order)
      @order = order
    end

    def last_payment
      last(@order.payments)
    end

    def last_pending_payment
      last(@order.pending_payments)
    end

    # The payment the customer chose to pay with. Customer credit is applied on
    # top of it and isn't a method anyone selects, so it's excluded here.
    def last_pending_payment_excluding_credit
      last(
        @order.pending_payments.reject do |payment|
          payment.payment_method == Spree::PaymentMethod.customer_credit
        end
      )
    end

    def last_customer_credit
      last(
        @order.pending_payments.select do |payment|
          payment.payment_method == Spree::PaymentMethod.customer_credit
        end
      )
    end

    def last_pending_paypal_payment
      last(
        @order.pending_payments.select do |payment|
          payment.payment_method&.type == "Spree::Gateway::PayPalExpress"
        end
      )
    end

    private

    # `max_by` avoids additional database queries when payments are loaded
    # already. There is usually only one payment and this shouldn't cause
    # any overhead compared to `order(:created_at).last`. Using `last`
    # without order is not deterministic.
    #
    # We are not using `updated_at` because all payments are touched when the
    # order is updated and then all payments have the same `updated_at` value.
    def last(payments)
      payments.max_by(&:created_at)
    end
  end
end
