class ShopController < BaseController
  layout "darkswarm"

  before_filter :set_distributor
  before_filter :set_order_cycles

  def index
  end

  private

  def set_distributor
    @distributor = current_distributor 
  end

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active
    
    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
