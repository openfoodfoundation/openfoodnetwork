require 'open_food_network/referer_parser'

class ApplicationController < ActionController::Base
  protect_from_forgery

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

  private

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
