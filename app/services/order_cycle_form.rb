class OrderCycleForm
  attr_accessor :order_cycle, :params

  def initialize(order_cycle, params)
    @order_cycle = order_cycle
    @params = params
  end

  def save
    order_cycle.assign_attributes(params[:order_cycle])
    order_cycle.save
  end
end
