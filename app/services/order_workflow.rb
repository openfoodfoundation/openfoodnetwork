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
  end
end
