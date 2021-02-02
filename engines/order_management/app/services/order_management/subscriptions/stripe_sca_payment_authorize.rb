# frozen_string_literal: true

module OrderManagement
  module Subscriptions
    class StripeScaPaymentAuthorize
      def initialize(order)
        @order = order
        @payment = OrderPaymentFinder.new(@order).last_pending_payment
      end

      def call!
        return unless @payment&.checkout?

        @payment.authorize!

        @order.errors.add(:base, I18n.t('authorization_failure')) unless @payment.pending?

        if @payment.cvv_response_message.present?
          PaymentMailer.authorize_payment(@payment).deliver_now
        end

        @payment
      end
    end
  end
end
