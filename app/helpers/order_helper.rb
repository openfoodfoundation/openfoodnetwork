# frozen_string_literal: true

module OrderHelper
  def last_payment_method(order)
    OrderPaymentFinder.new(order).last_payment&.payment_method
  end

  def outstanding_balance_label(order)
    order.outstanding_balance.label
  end

  def show_generate_invoice_button?(order)
    comparator = order_comparator(order)
    comparator.can_generate_new_invoice? ||
      comparator.can_update_latest_invoice?
  end

  def order_comparator(order)
    OrderInvoiceComparator.new(order)
  end
end
