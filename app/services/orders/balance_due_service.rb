# frozen_string_literal: true

module Orders
  # Adds a balance carried over from previous orders (a negative customer account balance) to the
  # customer's next order, clears the customer's account once that order is complete, and restores
  # the balance if the order is cancelled.
  # See Orders::CustomerCreditService#carry_balance for how a balance gets carried over.
  class BalanceDueService
    def initialize(order)
      @order = order
    end

    def apply
      return if customer.nil? || customer.guest?

      balance_due = -customer.credit_balance
      existing = adjustment
      if balance_due.positive?
        add_or_update_adjustment(existing, balance_due)
      elsif existing
        existing.destroy
      else
        return
      end

      order.all_adjustments.reset
      order.update_order!
    end

    # Called when the order completes, or is resumed after being cancelled.
    # `finalize!` only closes adjustments, so a finalized balance due adjustment means it's settled.
    def settle
      existing = adjustment
      return if existing.nil? || existing.finalized?

      existing.update_columns(state: "finalized")
      record_transaction(existing.amount, paid_description)
    end

    # Called when the order is cancelled: the customer owes the balance again
    def restore
      existing = adjustment
      return unless existing&.finalized?

      existing.update_columns(state: "closed")
      record_transaction(-existing.amount, restored_description)
    end

    def adjustment
      order.all_adjustments.find_by(originator_type: "Customer")
    end

    # The orders carried over since the customer's balance was last zero or in credit.
    def carried_over_orders
      transactions = customer.customer_account_transactions.includes(payment: :order)
        .order(id: :desc)
      unpaid = transactions.take_while { |transaction| transaction.balance.negative? }

      unpaid.select { |transaction| transaction.amount.negative? }
        .filter_map { |transaction| transaction.payment&.order }
        .uniq.reverse
    end

    private

    attr_reader :order

    delegate :customer, to: :order

    def add_or_update_adjustment(existing, balance_due)
      if existing
        existing.update_columns(amount: balance_due, label:)
      else
        # A closed adjustment keeps its amount: the order updater won't try to recalculate it.
        order.adjustments.create!(
          amount: balance_due, label:, originator: customer, order:, state: "closed"
        )
      end
    end

    def label
      t(:label, order_numbers: carried_over_orders.map(&:number).join(", "))
    end

    def paid_description
      t(:paid_description, order_number: order.number)
    end

    def restored_description
      t(:restored_description, order_number: order.number)
    end

    def record_transaction(amount, description)
      customer.with_lock do
        customer.customer_account_transactions.create!(
          amount:, currency: CurrentConfig.get(:currency), description:
        )
      end
    end

    def t(key, **)
      I18n.t(key, scope: "balance_due_service", **)
    end
  end
end
