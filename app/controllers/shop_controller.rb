# frozen_string_literal: true

class ShopController < BaseController
  layout "darkswarm"
  before_action :require_distributor_chosen, :set_order_cycles, except: :changeable_orders_alert

  def show
    redirect_to main_app.enterprise_shop_path(current_distributor)
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by(id: params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        @current_order_cycle = oc
        render json: @current_order_cycle, serializer: Api::OrderCycleSerializer
      else
        render status: :not_found, json: ""
      end
    else
      render json: current_order_cycle, serializer: Api::OrderCycleSerializer
    end
  end

  def changeable_orders_alert
    render layout: false
  end
end
