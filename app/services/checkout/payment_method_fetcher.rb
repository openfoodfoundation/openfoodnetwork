# frozen_string_literal: true

module Checkout
  class PaymentMethodFetcher
    def initialize(order)
      @order = order
    end

    def call
      latest_payment&.payment_method
    end

    private

    attr_reader :order

    def latest_payment
      order.payments.order(:created_at).last
    end
  end
end
