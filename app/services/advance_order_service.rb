class AdvanceOrderService
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def call
    shipping_method_id = @order.shipping_method.id if @order.shipping_method.present?

    while @order.state != "complete"
      break unless @order.next

      if @order.state == "delivery"
        @order.select_shipping_method(shipping_method_id) if shipping_method_id.present?
      end
    end
  end
end
