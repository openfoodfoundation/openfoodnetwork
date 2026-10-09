# frozen_string_literal: true

module Orders
  # Pays the balance due of a complete order with the customer's credit, as much as the credit
  # allows. Used by shop managers when the credit was added after the order was placed.
  #
  # A pending offline payment (cash, bank transfer...) is replaced by a new one for the remaining
  # amount, if any. Payments going through a gateway (card...) have to be voided first.
  class PayWithCreditService
    Response = CustomerCreditService::Response

    def initialize(order)
      @order = order
    end

    def call(user: nil)
      reason = blocker
      return Response.new(success: false, message: blocker_message(reason)) if reason

      amount = order.customer.with_lock do
        payment_method = invalidate_offline_payments
        payment = add_completed_credit_payment(user)
        add_remaining_payment(payment_method)
        payment.amount
      end

      Response.new(success: true, message: success_message(amount))
    rescue StandardError => e
      # The transaction rolled back, but the order in memory still has the changes
      order.reload
      Rails.logger.error("Orders::PayWithCreditService: #{e}")
      Alert.raise(e)
      Response.new(success: false, message: e.message)
    end

    # Returns the reason why the order can't be paid with credit, or nil if it can
    def blocker
      return :no_customer if order.customer.nil?
      return :order_not_complete unless order.complete? || order.resumed?
      return :nothing_to_pay unless order.new_outstanding_balance.positive?
      return :no_credit_available unless order.customer.credit_balance.positive?

      :pending_gateway_payment if pending_gateway_payment
    end

    def blocker_message(reason)
      I18n.t(reason, scope: "pay_with_credit_service.errors",
                     payment_method: pending_gateway_payment&.payment_method&.name)
    end

    private

    attr_reader :order

    # Only payments that don't go through a payment gateway can be replaced.
    def pending_gateway_payment
      order.payments.incomplete.not_customer_credit.find do |payment|
        !payment.payment_method.is_a?(Spree::PaymentMethod::Check)
      end
    end

    # Same as Spree::Payment#invalidate_old_payments, which runs when a payment is added, but done
    # before computing the amount to pay, so the fee of the replaced payment is left out.
    # Returns the payment method of the replaced payment.
    def invalidate_offline_payments
      payments = order.payments.incomplete.not_customer_credit.order(:id).to_a
      payments.each do |payment|
        payment.update_columns(state: "invalid", updated_at: Time.zone.now)
        payment.ensure_correct_adjustment
      end
      order.update_order!

      payments.last&.payment_method
    end

    def add_completed_credit_payment(user)
      amount = [order.customer.credit_balance, order.new_outstanding_balance].min
      # Another request may have paid the order in the meantime
      raise blocker_message(:nothing_to_pay) unless amount.positive?

      payment = order.payments.create!(
        payment_method: Spree::PaymentMethod.customer_credit, amount:, state: "checkout"
      )
      # Raises Spree::Core::GatewayError if the payment fails
      payment.internal_purchase!(user_id: user&.id)
      payment
    end

    def add_remaining_payment(payment_method)
      return if payment_method.nil? || !order.new_outstanding_balance.positive?

      payment = order.payments.create!(
        payment_method:, amount: order.new_outstanding_balance, state: "checkout"
      )
      # The new payment may come with a fee, which adds to the amount to pay
      order.update_order!
      payment.update!(amount: order.new_outstanding_balance)
    end

    def success_message(amount)
      I18n.t(:success, scope: "pay_with_credit_service",
                       amount: Spree::Money.new(amount, currency: order.currency))
    end
  end
end
