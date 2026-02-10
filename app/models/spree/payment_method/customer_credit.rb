# frozen_string_literal: true

module Spree
  class PaymentMethod
    class CustomerCredit < Spree::PaymentMethod
      # Main method called by Spree::Payment::Processing during checkout
      # - amount is in cents
      # - options: {
      #     customer_id:, payment_id:, order_number:
      #   }
      def purchase(amount, _source, options)
        calculated_amount = amount / 100.00

        customer = Customer.find_by(id: options[:customer_id])
        return error_response("customer_not_found") if customer.nil?
        return error_response("missing_payment") if options[:payment_id].nil?
        return error_response("credit_payment_method_missing") if payment_method.nil?

        available_credit = customer.customer_account_transactions.last&.balance
        return error_response("no_credit_available") if available_credit.nil?

        return error_response("not_enough_credit_available") if calculated_amount > available_credit

        customer.with_lock do
          description = I18n.t(
            "order_payment_description",
            scope: "credit_payment_method",
            order_number: options[:order_number]
          )
          customer.customer_account_transactions.create(
            amount: -calculated_amount,
            currency:,
            payment_method:,
            payment_id: options[:payment_id],
            description:
          )
        end
        message = I18n.t("success", scope: "credit_payment_method")
        ActiveMerchant::Billing::Response.new(true, message)
      end

      def method_type
        "check" # empty view
      end

      def source_required?
        false
      end

      def internal?
        true
      end

      private

      def payment_method
        Spree::PaymentMethod.find_by(
          name: Rails.application.config.credit_payment_method[:name]
        )
      end

      def error_response(translation_key)
        message = I18n.t(translation_key, scope: "credit_payment_method.errors")
        ActiveMerchant::Billing::Response.new(false, message)
      end

      def currency
        CurrentConfig.get(:currency)
      end
    end
  end
end
