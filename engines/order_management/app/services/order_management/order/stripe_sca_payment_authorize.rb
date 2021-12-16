# frozen_string_literal: true

module OrderManagement
  module Order
    class StripeScaPaymentAuthorize
      include FullUrlHelper

      def initialize(order, off_session: false)
        @order = order
        @payment = OrderPaymentFinder.new(order).last_pending_payment
        @off_session = off_session
      end

      def call!(redirect_url = full_order_path(order))
        return unless payment&.checkout?

        payment.authorize!(redirect_url)

        order.errors.add(:base, I18n.t('authorization_failure')) unless successfully_processed?
        send_auth_emails if requires_authorization_emails?

        payment
      end

      private

      attr_reader :order, :payment, :off_session

      def successfully_processed?
        payment.pending? || payment.requires_authorization?
      end

      def requires_authorization_emails?
        payment.requires_authorization? && off_session
      end

      def send_auth_emails
        PaymentMailer.authorize_payment(payment).deliver_now
        PaymentMailer.authorization_required(payment).deliver_now
      end
    end
  end
end
