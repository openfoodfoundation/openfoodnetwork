class ShopController < BaseController
  layout "darkswarm"

  before_filter :set_distributor
  before_filter :set_order_cycles

  def show
    # All suppliers of all our products
    @producers = Exchange.where(receiver_id: @distributor.id).map{ |ex| ex.variants.map {|v| v.product.supplier }}.flatten.uniq 
  end
  
  def products
    unless @products = current_order_cycle.andand
      .products_distributed_by(@distributor)
      .select(&:has_stock?)
      render json: "", status: 404 
    end
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        render partial: "shop/order_cycle"
      else
        render status: 404, json: ""
      end
    else
      render partial: "shop/order_cycle"
    end
  end

  private

  def set_distributor

    unless @distributor = current_distributor 
      redirect_to root_path
    end
  end

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active
    
    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
