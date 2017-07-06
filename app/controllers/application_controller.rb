require 'open_food_network/referer_parser'

class ApplicationController < ActionController::Base
  protect_from_forgery

  prepend_before_filter :restrict_iframes

  include EnterprisesHelper
  helper CssSplitter::ApplicationHelper

  def redirect_to(options = {}, response_status = {})
    ::Rails.logger.error("Redirected by #{caller(1).first rescue "unknown"}")
    super(options, response_status)
  end

  def set_checkout_redirect
    referer_path = OpenFoodNetwork::RefererParser::path(request.referer)
    if referer_path
      session["spree_user_return_to"] = [main_app.checkout_path].include?(referer_path) ? referer_path : root_path
    end
  end

  def shopfront_session
    session[:safari_fix] = true
    render 'shop/shopfront_session', layout: false
  end

  def enable_embedded_styles
    session[:embedded_shopfront] = true
    render json: {}, status: 200
  end

  def disable_embedded_styles
    session.delete :embedded_shopfront
    session.delete :shopfront_redirect
    render json: {}, status: 200
  end

  protected

  def after_sign_in_path_for(resource_or_scope)
    return session[:shopfront_redirect] if session[:shopfront_redirect]
    stored_location_for(resource_or_scope) || signed_in_root_path(resource_or_scope)
  end

  def after_sign_out_path_for(_resource_or_scope)
    session[:shopfront_redirect] ? session[:shopfront_redirect] : root_path
  end

  private

  def restrict_iframes
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['Content-Security-Policy'] = "frame-ancestors 'none'"
  end

  def enable_embedded_shopfront
    whitelist = Spree::Config[:embedded_shopfronts_whitelist]
    return unless Spree::Config[:enable_embedded_shopfronts] && whitelist.present?
    return if request.referer && URI(request.referer).scheme != 'https' && !Rails.env.test?

    response.headers.delete 'X-Frame-Options'
    response.headers['Content-Security-Policy'] = "frame-ancestors #{whitelist}"

    check_embedded_request
    set_embedded_layout
  end

  def check_embedded_request
    return unless params[:embedded_shopfront]

    # Show embedded shopfront CSS
    session[:embedded_shopfront] = true

    # Get shopfront slug and set redirect path
    if params[:controller] == 'enterprises' && params[:action] == 'shop' && params[:id]
      slug = params[:id]
      session[:shopfront_redirect] = '/' + slug + '/shop?embedded_shopfront=true'
    end
  end

  def set_embedded_layout
    return unless session[:embedded_shopfront]
    @shopfront_layout = 'embedded'
  end

  def action
    params[:action].to_sym
  end

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
    # This condition is more rigourous than required by development to avoid coupling this
    # condition to every controller spec
    if current_distributor && current_order &&
        current_distributor.respond_to?(:ready_for_checkout?) &&
        !current_distributor.ready_for_checkout?

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
