class OrderWorkflow
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def complete
    advance_order(advance_order_options)
  end

  def complete!
    advance_order!(advance_order_options)
  end

  def next(options = {})
    result = advance_order_one_step

    after_transition_hook(options)

    result
  end

  private

  def advance_order_options
    shipping_method_id = order.shipping_method.id if order.shipping_method.present?
    { shipping_method_id: shipping_method_id }
  end

  def advance_order(options)
    until order.state == "complete"
      break unless order.next

      after_transition_hook(options)
    end
  end

  def advance_order!(options)
    until order.completed?
      order.next!
      after_transition_hook(options)
    end
  end

  def advance_order_one_step
    tries ||= 3
    order.next
  rescue ActiveRecord::StaleObjectError
    retry unless (tries -= 1).zero?
    false
  end

  def after_transition_hook(options)
    if order.state == "delivery" && (options[:shipping_method_id])
      order.select_shipping_method(options[:shipping_method_id])
    end

    persist_all_payments if order.state == "payment"
  end

  # When a payment fails, the order state machine stays in 'payment' and rollbacks all transactions
  #   This rollback also reverts the payment state from 'failed', 'void' or 'invalid' to 'pending'
  #   Despite the rollback, the in-memory payment still has the correct state, so we persist it
  def persist_all_payments
    order.payments.each do |payment|
      in_memory_payment_state = payment.state
      if different_from_db_payment_state?(in_memory_payment_state, payment.id)
        payment.reload.update(state: in_memory_payment_state)
      end
    end
  end

  # Verifies if the in-memory payment state is different from the one stored in the database
  #   This is be done without reloading the payment so that in-memory data is not changed
  def different_from_db_payment_state?(in_memory_payment_state, payment_id)
    in_memory_payment_state != Spree::Payment.find(payment_id).state
  end
end
