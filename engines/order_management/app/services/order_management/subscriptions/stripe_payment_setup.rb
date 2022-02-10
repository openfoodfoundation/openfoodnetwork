# frozen_string_literal: true

module OrderManagement
  module Subscriptions
    class StripePaymentSetup
      def initialize(order)
        @order = order
        @payment = OrderPaymentFinder.new(@order).last_pending_payment
      end

      def call!
        return if @payment.blank?

        ensure_payment_source
        @payment
      end

      private

      def ensure_payment_source
        return unless stripe_payment_method? && !card_set?

        if saved_credit_card.present? && allow_charges?
          use_saved_credit_card
        else
          @order.errors.add(:base, :no_card)
        end
      end

      def stripe_payment_method?
        @payment.payment_method.type == "Spree::Gateway::StripeSCA"
      end

      def card_set?
        @payment.source.is_a? Spree::CreditCard
      end

      def saved_credit_card
        @order.user.default_card
      end

      def allow_charges?
        @order.customer.allow_charges?
      end

      def use_saved_credit_card
        @payment.update(source: saved_credit_card)
      end
    end
  end
end
