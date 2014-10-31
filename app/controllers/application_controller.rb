class ApplicationController < ActionController::Base
  protect_from_forgery

  include EnterprisesHelper

  def redirect_to(options = {}, response_status = {})
    ::Rails.logger.error("Redirected by #{caller(1).first rescue "unknown"}")
    super(options, response_status)
  end

  def after_sign_in_path_for(resource)
    if request.referer and referer_path = URI(request.referer).path
      [main_app.checkout_path].include?(referer_path) ? referer_path : root_path
    else
      root_path
    end
  end


  private

  def require_distributor_chosen
    unless @distributor = current_distributor
      redirect_to spree.root_path
      false
    end
  end

  def require_order_cycle
    unless current_order_cycle
      redirect_to main_app.shop_path
    end
  end

  def check_hub_ready_for_checkout
    if current_distributor && !current_distributor.ready_for_checkout?
      current_order.empty!
      current_order.set_distribution! nil, nil
      flash[:info] = "The hub you have selected is temporarily closed for orders. Please try again later."
      redirect_to root_url
    end
  end

  def check_order_cycle_expiry
    if current_order_cycle.andand.closed?
      session[:expired_order_cycle_id] = current_order_cycle.id
      current_order.empty!
      current_order.set_order_cycle! nil
      flash[:info] = "The order cycle you've selected has just closed. Please try again!"
      redirect_to root_url
    end
  end


  # All render calls within the block will be performed with the specified format
  # Useful for rendering html within a JSON response, particularly if the specified
  # template or partial then goes on to render further partials without specifying
  # their format.
  def with_format(format, &block)
    old_formats = formats
    self.formats = [format]
    block.call
    self.formats = old_formats
    nil
  end

end
