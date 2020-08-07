# frozen_string_literal: true

module Spree
  class PaymentMethod
    class Check < Spree::PaymentMethod
      def actions
        %w{capture void}
      end

      # Indicates whether its possible to capture the payment
      def can_capture?(payment)
        ['checkout', 'pending'].include?(payment.state)
      end

      # Indicates whether its possible to void the payment.
      def can_void?(payment)
        payment.state != 'void'
      end

      def capture(*_args)
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def void(*_args)
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def source_required?
        false
      end
    end
  end
end
