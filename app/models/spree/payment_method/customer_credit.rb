# frozen_string_literal: true

module Spree
  class PaymentMethod
    class CustomerCredit < Spree::PaymentMethod
      # Name and description are translatable string, to allow instances to customise them
      def name
        "credit_payment_method.name"
      end

      def description
        "credit_payment_method.description"
      end

      def actions
        %w{internal_void}
      end

      # We should only void complete payment, otherwise we will be refunding credit that was
      # not used in the first place.
      def can_internal_void?(payment)
        payment.state == "completed" && !settled_carry_over?(payment.id)
      end

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

        available_credit = customer.credit_balance
        return error_response("no_credit_available") if available_credit.zero?

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
            payment_id: options[:payment_id],
            description:
          )
        end
        message = I18n.t("success", scope: "credit_payment_method")
        ActiveMerchant::Billing::Response.new(true, message)
      end

      # Main method called by Spree::Payment::Processing for void
      # - amount is in cents
      # - options: {
      #     customer_id:, payment_id:, order_number:, user_id: (optional)
      #   }
      def void(amount, _source, options)
        calculated_amount = amount / 100.00

        customer = Customer.find_by(id: options[:customer_id])
        return error_response("customer_not_found") if customer.nil?
        return error_response("missing_payment") if options[:payment_id].nil?
        if settled_carry_over?(options[:payment_id])
          return error_response("balance_already_settled")
        end

        customer.with_lock do
          description = I18n.t(
            "order_void_description",
            scope: "credit_payment_method",
            order_number: options[:order_number]
          )
          customer.customer_account_transactions.create(
            amount: calculated_amount,
            currency:,
            payment_id: options[:payment_id],
            description:,
            created_by_id: options[:user_id]
          )
        end

        message = I18n.t("void_success", scope: "credit_payment_method")
        ActiveMerchant::Billing::Response.new(true, message)
      end

      def method_type
        "check" # empty view
      end

      def source_required?
        false
      end

      private

      # A payment that carried an order's balance due over to the customer's account (see
      # Orders::CustomerCreditService#carry_balance) is the only one that leaves the account
      # negative. Once the customer no longer owes that balance (they paid it on a later order, or
      # it was waived), voiding the payment would give them the money back a second time.
      def settled_carry_over?(payment_id)
        debt = CustomerAccountTransaction.where(payment_id:).where(amount: ...0).order(:id).first
        return false if debt.nil? || !debt.balance.negative?

        debt.customer.outstanding_carry_over_transactions.exclude?(debt)
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
