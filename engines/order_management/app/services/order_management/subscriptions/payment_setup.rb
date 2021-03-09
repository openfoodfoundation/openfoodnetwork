# frozen_string_literal: true

module OrderManagement
  module Subscriptions
    class PaymentSetup
      def initialize(order)
        @order = order
      end

      def call!
        payment = create_payment
        return if @order.errors.any?

        balance = OrderBalance.new(@order)
        payment.update(amount: balance.to_f)
        payment
      end

      private

      def create_payment
        payment = OrderPaymentFinder.new(@order).last_pending_payment
        return payment if payment.present?

        @order.payments.create(
          payment_method_id: @order.subscription.payment_method_id
        )
      end
    end
  end
end
