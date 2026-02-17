# frozen_string_literal: true

module Spree
  class PaymentMethod
    class Check < Spree::PaymentMethod
      def actions
        %w{capture_and_complete_order void}
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
