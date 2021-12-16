# frozen_string_literal: true

module OrderManagement
  module Order
    class StripeScaPaymentAuthorize
      include FullUrlHelper

      def initialize(order, off_session: false)
        @order = order
        @payment = OrderPaymentFinder.new(@order).last_pending_payment
        @off_session = off_session
      end

      def call!(redirect_url = full_order_path(@order))
        return unless @payment&.checkout?

        @payment.authorize!(redirect_url)

        unless @payment.pending? || @payment.requires_authorization?
          @order.errors.add(:base, I18n.t('authorization_failure'))
        end

        return @payment unless @payment.requires_authorization? && off_session

        PaymentMailer.authorize_payment(@payment).deliver_now
        PaymentMailer.authorization_required(@payment).deliver_now
      end

      private

      attr_reader :off_session
    end
  end
end
