class Shop::ShopController < BaseController
  layout "darkswarm"
  before_filter :require_distributor_chosen
  before_filter :set_order_cycles

  def show
  end
  
  def products
    unless @products = current_order_cycle.andand
      .valid_products_distributed_by(current_distributor).andand
      .select { |p| !p.deleted? && p.has_stock_for_distribution?(current_order_cycle, current_distributor) }.andand
      .sort_by {|p| p.name }
      render json: "", status: 404
    end
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        render partial: "shop/shop/order_cycle"
      else
        render status: 404, json: ""
      end
    else
      render partial: "shop/shop/order_cycle"
    end
  end

  private

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active
    
    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1 and current_order_cycle.nil?
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
