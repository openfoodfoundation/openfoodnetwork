class AdvanceOrderService
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def call
    while order.next; end
  end
end
