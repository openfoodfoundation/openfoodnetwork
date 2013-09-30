Spree::StoreController.class_eval do
  include OrderCyclesHelper

  before_filter :check_order_cycle_expiry


  private

  def check_order_cycle_expiry
    if current_order_cycle.andand.expired?
      session[:expired_order_cycle_id] = current_order_cycle.id
      current_order.empty!
      current_order.set_order_cycle! nil
      redirect_to order_cycle_expired_orders_path
    end
  end

end
