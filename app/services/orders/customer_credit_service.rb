# frozen_string_literal: true

module Orders
  class CustomerCreditService # rubocop:disable Metrics/ClassLength
    def initialize(order)
      @order = order
    end

    def apply
      add_payment_with_credit if credit_available?
    end

    def refund(user: nil) # rubocop:disable Metrics/AbcSize
      if order.payment_state != "credit_owed"
        return Response.new(
          success: false, message: I18n.t(:no_credit_owed, scope: translation_scope)
        )
      end

      if order.customer.nil?
        return Response.new(
          success: false, message: I18n.t(:customer_missing, scope: translation_scope)
        )
      end

      amount = order.new_outstanding_balance
      order.customer.with_lock do
        payment = order.payments.create!( payment_method: credit_payment_method, amount: amount,
                                          state: "completed", skip_source_validation: true)

        options = { customer_id: order.customer_id, payment_id: payment.id,
                    order_number: order.number, user_id: user&.id }
        response = credit_payment_method.void((-1 * amount * 100).round, nil, options)

        raise response.message if response.failure?

        Response.new(success: true, message: I18n.t(:refund_sucessful, scope: translation_scope))
      end
    rescue StandardError => e
      # Even though the transaction rolled back, the order still have a payment in memory,
      # so we reload the payments so the payment doesn't get saved later on
      order.payments.reload
      log_error(e)
      Response.new(success: false, message: e.to_s)
    end

    # Pays the balance due of a complete order with the customer's credit, as much as the credit
    # allows. Pending offline payments are voided first. Payments going through a payment gateway
    # have to be voided by the shop manager beforehand.
    def pay_order(user:)
      return failure(I18n.t(:user_missing, scope: pay_order_scope)) if user.nil?
      return failure(can_pay_message) unless can_pay?

      payment = order.customer.with_lock do
        void_pending_payments
        add_completed_credit_payment(user)
      end

      Response.new(
        success: true,
        message: I18n.t(:pay_order_successful, scope: translation_scope,
                                               amount: payment.display_amount.to_s)
      )
    rescue StandardError => e
      # The transaction rolled back, but the order in memory still has the changes
      order.reload
      log_error(e)
      failure(e.message)
    end

    def can_pay?
      cannot_pay_reason.nil?
    end

    def can_pay_message
      I18n.t(cannot_pay_reason, scope: pay_order_scope,
                                payment_method: pending_gateway_payment&.payment_method&.name)
    end

    def cannot_pay_reason
      return :order_not_complete unless order.complete? || order.resumed?
      return :nothing_to_pay unless order.new_outstanding_balance.positive?
      return :no_credit_available unless credit_available?

      :pending_gateway_payment if pending_gateway_payment
    end

    private

    attr_reader :order

    def pending_gateway_payment
      order.payments.incomplete.not_customer_credit.find do |payment|
        payment.payment_method.external_gateway?
      end
    end

    def void_pending_payments
      order.payments.incomplete.not_customer_credit.each(&:void_transaction!)
      # Voiding drops the payment fee, but the order total is only updated here
      order.update_order!
    end

    def add_completed_credit_payment(user)
      # Another request may have paid the order in the meantime
      unless order.new_outstanding_balance.positive?
        raise I18n.t(:nothing_to_pay, scope: pay_order_scope)
      end

      @available_credit = nil # Read it again now that the customer is locked
      payment = apply
      raise I18n.t(:credit_payment_failed, scope: pay_order_scope) if payment.nil?

      # Raises Spree::Core::GatewayError if the payment fails
      payment.internal_purchase!(user_id: user.id)
      payment
    end

    def add_payment_with_credit
      if credit_payment_method.nil?
        error_message = I18n.t(:credit_payment_method_missing, scope: translation_scope)
        log_error(error_message)
        return
      end

      # Delete existing payment with credit, so we can apply new credit amount if needed
      order.payments.customer_credit.incomplete&.destroy_all

      # we are already in a transaction because the order is locked, so we force creating a new one
      # to make sure the rollback works as expected :
      # https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
      ActiveRecord::Base.transaction(requires_new: true) do
        # Only what is left to pay: a complete order may have completed payments already
        amount = [available_credit, order.total - order.payment_total].min
        order.payments.create!(payment_method: credit_payment_method, amount:,
                               state: "checkout")
      end
    rescue StandardError => e
      # Even though the transaction rolled back, the order still have a payment in memory,
      # so we reload the payments so the payment doesn't get saved later on
      order.payments.reload
      log_error(e)
      nil
    end

    def credit_available?
      return false if order.customer.nil?

      return false if order.customer.guest?

      available_credit > 0
    end

    def available_credit
      @available_credit ||= order.customer.customer_account_transactions.last&.balance || 0.00
    end

    def credit_payment_method
      Spree::PaymentMethod.customer_credit
    end

    def log_error(error)
      Rails.logger.error("Orders::CustomerCreditService: #{error}")
      Alert.raise(error)
    end

    def translation_scope
      "customer_credit_service"
    end

    def pay_order_scope
      "#{translation_scope}.pay_order_errors"
    end

    def failure(message)
      Response.new(success: false, message:)
    end

    class Response
      attr_reader :message

      def initialize(success:, message:)
        @success = success
        @message = message
      end

      def success?
        @success
      end

      def failure?
        !success?
      end
    end
  end
end
