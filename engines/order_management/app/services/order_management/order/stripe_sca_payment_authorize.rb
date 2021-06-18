# frozen_string_literal: true

module OrderManagement
  module Order
    class StripeScaPaymentAuthorize
      include FullUrlHelper

      def initialize(order)
        @order = order
        @payment = OrderPaymentFinder.new(@order).last_pending_payment
      end

      def call!(redirect_url = full_order_path(@order))
        return unless @payment&.checkout?

        @payment.authorize!(redirect_url)

        unless @payment.pending? || @payment.requires_authorization?
          @order.errors.add(:base, I18n.t('authorization_failure'))
        end

        @payment
      end
    end
  end
end
