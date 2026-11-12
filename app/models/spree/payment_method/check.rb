# frozen_string_literal: true

module Spree
  class PaymentMethod
    class Check < Spree::PaymentMethod
      def actions
        %w{capture_and_complete_order void}
      end

      # Indicates whether its possible to capture the payment
      def can_capture_and_complete_order?(payment)
        ['checkout', 'pending'].include?(payment.state)
      end

      # Indicates whether its possible to void the payment.
      # A canceled payment can't be voided: its money was never taken, so there is
      # nothing to give back.
      def can_void?(payment)
        payment.state != 'void' && payment.state != 'invalid'
      end

      def capture(*_args)
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def void(*_args)
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def payment_source_class
        nil
      end

      def source_required?
        false
      end
    end
  end
end
