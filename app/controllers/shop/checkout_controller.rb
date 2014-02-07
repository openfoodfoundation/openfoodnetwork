class Shop::CheckoutController < BaseController
  layout 'darkswarm'

  before_filter :set_distributor
  before_filter :require_order_cycle
  
  def new

  end

  private

  def set_distributor
    unless @distributor = current_distributor 
      redirect_to root_path
    end
  end

  def require_order_cycle
    unless current_order_cycle
      redirect_to shop_path
    end
  end
end
