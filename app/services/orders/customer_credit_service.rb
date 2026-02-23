# frozen_string_literal: true

module Orders
  class CustomerCreditService
    def initialize(order)
      @order = order
    end

    def apply
      add_payment_with_credit if credit_available?
    end

    def refund # rubocop:disable Metrics/AbcSize
      if order.payment_state != "credit_owed"
        return Response.new(
          success: false, message: I18n.t(:no_credit_owed, scope: translation_scope)
        )
      end

      if credit_payment_method.nil?
        error_message = I18n.t(:credit_payment_method_missing, scope: translation_scope)
        log_error(error_message)
        return Response.new(success: false, message: error_message)
      end

      amount = order.new_outstanding_balance
      order.customer.with_lock do
        payment = order.payments.create!( payment_method: credit_payment_method, amount: amount,
                                          state: "completed", skip_source_validation: true)

        options = { customer_id: order.customer_id, payment_id: payment.id,
                    order_number: order.number }
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

    private

    attr_reader :order

    def add_payment_with_credit
      if credit_payment_method.nil?
        error_message = I18n.t(:credit_payment_method_missing, scope: translation_scope)
        log_error(error_message)
        return
      end

      return if order.payments.where(payment_method: credit_payment_method).exists?

      # we are already in a transaction because the order is locked, so we force creating a new one
      # to make sure the rollback works as expected :
      # https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
      ActiveRecord::Base.transaction(requires_new: true) do
        amount = [available_credit, order.total].min
        payment = order.payments.create!(payment_method: credit_payment_method, amount:)
        payment.internal_purchase!
      end
    rescue StandardError => e
      # Even though the transaction rolled back, the order still have a payment in memory,
      # so we reload the payments so the payment doesn't get saved later on
      order.payments.reload
      log_error(e)
    end

    def credit_available?
      return false if order.customer.nil?

      available_credit > 0
    end

    def available_credit
      @available_credit ||= order.customer.customer_account_transactions.last&.balance || 0.00
    end

    def credit_payment_method
      order.distributor.payment_methods.customer_credit
    end

    def log_error(error)
      Rails.logger.error("Orders::CustomerCreditService: #{error}")
      Alert.raise(error)
    end

    def translation_scope
      "orders.customer_credit_service"
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
