require 'open_food_network/scope_product_to_hub'

class ShopController < BaseController
  layout "darkswarm"
  before_filter :require_distributor_chosen
  before_filter :set_order_cycles
  before_filter :load_active_distributors

  def show
  end
  
  def products
    # Can we make this query less slow?
    #
    if current_order_cycle
      @products = current_order_cycle.
        valid_products_distributed_by(current_distributor).
        each { |p| p.scope_to_hub current_distributor }.
        select { |p| !p.deleted? && p.has_stock_for_distribution?(current_order_cycle, current_distributor) }.
        sort_by(&:name)

      render status: 200,
        json: ActiveModel::ArraySerializer.new(@products, each_serializer: Api::ProductSerializer, 
        current_order_cycle: current_order_cycle, current_distributor: current_distributor).to_json 
    else
      render json: "", status: 404
    end
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        render partial: "json/order_cycle"
      else
        render status: 404, json: ""
      end
    else
      render partial: "json/order_cycle"
    end
  end

  private

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active
    
    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
