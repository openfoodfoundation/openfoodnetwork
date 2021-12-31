# frozen_string_literal: true

# Note: "off-session" processing happens when a payment is placed on behalf of a user when
# they are currently offline. This can happen with backoffice orders or subscriptions.
# In that case; if the payment requires authorization in Stripe, we send an email so the user
# can authorize it later (asynchronously).

module OrderManagement
  module Order
    class StripeScaPaymentAuthorize
      include Rails.application.routes.url_helpers

      def initialize(order, payment: nil, off_session: false, notify_hub: false)
        @order = order
        @payment = payment || OrderPaymentFinder.new(order).last_pending_payment
        @off_session = off_session
        @notify_hub = notify_hub
      end

      def call!(return_url = off_session_return_url)
        return unless payment&.checkout?

        payment.authorize!(return_url)

        order.errors.add(:base, I18n.t('authorization_failure')) unless successfully_processed?
        send_auth_emails if requires_authorization_emails?

        payment
      end

      private

      attr_reader :order, :payment, :off_session, :notify_hub

      def successfully_processed?
        payment.pending? || payment.requires_authorization?
      end

      def requires_authorization_emails?
        payment.requires_authorization? && off_session
      end

      def send_auth_emails
        PaymentMailer.authorize_payment(payment).deliver_now
        PaymentMailer.authorization_required(payment).deliver_now if notify_hub
      end

      def off_session_return_url
        payment_gateways_authorize_stripe_url(order)
      end
    end
  end
end
