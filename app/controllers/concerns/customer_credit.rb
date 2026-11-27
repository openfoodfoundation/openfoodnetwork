# frozen_string_literal: true

module CustomerCredit
  extend ActiveSupport::Concern

  def calculate_credit(order)
    order.payments.incomplete.customer_credit.sum(:amount)
  end

  # The customer credit used, and any balance carried over from the customer's previous orders
  # (explained on the payment step)
  def load_credit_and_balance_due(order)
    @paid_with_credit = calculate_credit(order)

    balance_due_service = Orders::BalanceDueService.new(order)
    @balance_due_adjustment = balance_due_service.adjustment
    @carried_over_orders = @balance_due_adjustment ? balance_due_service.carried_over_orders : []
  end
end
