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
    if order.state == "delivery"
      order.select_shipping_method(options[:shipping_method_id]) if options[:shipping_method_id]
    end

    persist_all_payments if order.state == "payment"
  end

  # When a payment fails, the order state machine rollbacks all transactions
  #   Here we ensure we always persist all payments
  def persist_all_payments
    order.payments.each do |payment|
      original_payment_state = payment.state
      if original_payment_state != payment.reload.state
        payment.update(state: original_payment_state)
      end
    end
  end

end
