# frozen_string_literal: true

module Orders
  class CustomerCreditService
    def initialize(order)
      @order = order
    end

    def apply
      add_payment_with_credit if credit_available?
    end

    private

    attr_reader :order

    def add_payment_with_credit
      credit_payment_method = order.distributor.payment_methods.customer_credit

      if credit_payment_method.nil?
        error_message = "Customer credit payment method is missing, please check configuration"
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

    def log_error(error)
      Rails.logger.error("Orders::CustomerCreditService: #{error}")
      Alert.raise(error)
    end
  end
end
