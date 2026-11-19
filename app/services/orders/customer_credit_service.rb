# frozen_string_literal: true

module Orders
  class CustomerCreditService
    def initialize(order)
      @order = order
    end

    def apply
      add_payment_with_credit if credit_available?
    end

    def refund(user: nil) # rubocop:disable Metrics/AbcSize
      return failure(:no_credit_owed) if order.payment_state != "credit_owed"
      return failure(:customer_missing) if order.customer.nil?

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

    # Settles an underpaid order by moving its balance due to the customer's account: the order is
    # paid with a customer credit payment, and a negative account transaction records the debt,
    # which is added to the customer's next order (see Orders::BalanceDueService).
    # The caller needs to update the order afterwards so it's marked as paid.
    def carry_balance(user: nil)
      error_key = carry_balance_error_key
      return failure(error_key) if error_key

      order.customer.with_lock { create_carry_balance_records(order.new_outstanding_balance, user) }

      Response.new(success: true, message: I18n.t(:carry_over_successful, scope: translation_scope))
    rescue StandardError => e
      order.payments.reload
      log_error(e)
      Response.new(success: false, message: e.to_s)
    end

    private

    attr_reader :order

    def carry_balance_error_key
      if order.customer.nil?
        :customer_missing
      elsif order.payment_state != "balance_due"
        :no_balance_due
      elsif order.payments.completed.none?
        :no_completed_payment
      elsif order.customer.guest?
        :guest_customer
      elsif credit_payment_method.nil?
        :credit_payment_method_missing
      end
    end

    def failure(translation_key)
      Response.new(success: false, message: I18n.t(translation_key, scope: translation_scope))
    end

    def create_carry_balance_records(amount, user)
      payment = order.payments.create!(payment_method: credit_payment_method, amount:,
                                       state: "completed", skip_source_validation: true)
      order.customer.customer_account_transactions.create!(
        amount: -amount,
        currency: CurrentConfig.get(:currency),
        payment:,
        created_by: user,
        description: I18n.t(:carry_over_description, scope: translation_scope,
                                                     order_number: order.number)
      )
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
        amount = [available_credit, order.total].min
        order.payments.create!(payment_method: credit_payment_method, amount:,
                               state: "checkout")
      end
    rescue StandardError => e
      # Even though the transaction rolled back, the order still have a payment in memory,
      # so we reload the payments so the payment doesn't get saved later on
      order.payments.reload
      log_error(e)
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
  end
end
