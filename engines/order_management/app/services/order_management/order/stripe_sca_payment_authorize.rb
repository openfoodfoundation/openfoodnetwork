# frozen_string_literal: true

module OrderManagement
  module Order
    class StripeScaPaymentAuthorize
      include FullUrlHelper

      def initialize(order)
        @order = order
        @payment = OrderPaymentFinder.new(@order).last_pending_payment
      end

      def call!(redirect_url = full_order_path(@order), send_emails = true)
        return unless @payment&.checkout?

        @payment.authorize!(redirect_url)

        @order.errors.add(:base, I18n.t('authorization_failure')) unless @payment.pending?

        if send_emails && @payment.authorization_action_required?
          PaymentMailer.authorize_payment(@payment).deliver_now
          PaymentMailer.authorization_required(@payment).deliver_now
        end

        @payment
      end
    end
  end
end
