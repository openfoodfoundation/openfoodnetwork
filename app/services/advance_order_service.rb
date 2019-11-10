class AdvanceOrderService
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def call
    advance_order(advance_order_options)
  end

  def call!
    advance_order!(advance_order_options)
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

  def after_transition_hook(options)
    if order.state == "delivery"
      order.select_shipping_method(options[:shipping_method_id]) if options[:shipping_method_id]
    end
  end
end
