class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_certified_hostname

  include EnterprisesHelper

  def after_sign_in_path_for(resource)
    if request.referer and referer_path = URI(request.referer).path
      [main_app.shop_checkout_path].include?(referer_path) ? referer_path : root_path
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

  def check_order_cycle_expiry
    if current_order_cycle.andand.closed?
      session[:expired_order_cycle_id] = current_order_cycle.id
      current_order.empty!
      current_order.set_order_cycle! nil
      redirect_to spree.order_cycle_expired_orders_path
    end
  end

  # There are several domains that point to the production server, but only one
  # (vic.openfoodnetwork.org) that has the SSL certificate. Redirect all requests to this
  # domain to avoid showing customers a scary invalid certificate error.
  def require_certified_hostname
    certified_host = "vic.openfoodnetwork.org"

    if Rails.env.production? && request.host != certified_host
      redirect_to "http://#{certified_host}#{request.fullpath}"
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
