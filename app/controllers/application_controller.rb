# frozen_string_literal: true

require_dependency 'spree/authentication_helpers'
require "application_responder"
require 'cancan'
require 'spree/core/controller_helpers/auth'
require 'spree/core/controller_helpers/respond_with'
require 'spree/core/controller_helpers/ssl'
require 'spree/core/controller_helpers/common'
require 'open_food_network/referer_parser'

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html

  helper 'spree/base'
  helper 'spree/orders'
  helper 'shared'
  helper 'enterprises'
  helper 'order_cycles'
  helper 'order'
  helper 'shop'
  helper 'injection'
  helper 'markdown'
  helper 'footer_links'
  helper 'discourse'
  helper 'checkout'

  protect_from_forgery

  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::RespondWith
  include Spree::Core::ControllerHelpers::SSL
  include Spree::Core::ControllerHelpers::Common

  prepend_before_action :restrict_iframes
  before_action :set_cache_headers # prevent cart emptying via cache when using back button #1213

  include RawParams
  include EnterprisesHelper
  include Spree::AuthenticationHelpers

  # Helper for debugging strong_parameters
  rescue_from ActiveModel::ForbiddenAttributesError, with: :print_params
  def print_params
    raise ActiveModel::ForbiddenAttributesError, params.to_s
  end

  respond_to :html

  def redirect_to(options = {}, response_status = {})
    ::Rails.logger.error("Redirected by #{begin
                                            caller(1).first
                                          rescue StandardError
                                            'unknown'
                                          end}")
    super(options, response_status)
  end

  def set_checkout_redirect
    referer_path = OpenFoodNetwork::RefererParser.path(request.referer)
    if referer_path
      is_checkout_path_the_referer = [main_app.checkout_path].include?(referer_path)
      session["spree_user_return_to"] = if is_checkout_path_the_referer
                                          referer_path
                                        else
                                          main_app.root_path
                                        end
    end
  end

  def shopfront_session
    session[:safari_fix] = true
    render 'shop/shopfront_session', layout: false
  end

  def enable_embedded_styles
    session[:embedded_shopfront] = true
    render json: {}, status: :ok
  end

  def disable_embedded_styles
    session.delete :embedded_shopfront
    session.delete :shopfront_redirect
    render json: {}, status: :ok
  end

  protected

  def after_sign_in_path_for(resource_or_scope)
    return session[:shopfront_redirect] if session[:shopfront_redirect]

    stored_location_for(resource_or_scope) || main_app.root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    shopfront_redirect || main_app.root_path
  end

  private

  def shopfront_redirect
    session[:shopfront_redirect]
  end

  def restrict_iframes
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['Content-Security-Policy'] = "frame-ancestors 'none'"
  end

  def enable_embedded_shopfront
    embed_service = EmbeddedPageService.new(params, session, request, response)
    embed_service.embed!
    @shopfront_layout = 'embedded' if embed_service.use_embedded_layout?
  end

  def action
    params[:action].to_sym
  end

  def require_distributor_chosen
    unless @distributor = current_distributor
      redirect_to main_app.root_path
      false
    end
  end

  def require_order_cycle
    unless current_order_cycle
      redirect_to main_app.shop_path
    end
  end

  def check_hub_ready_for_checkout
    if current_distributor_closed?
      current_order.empty!
      current_order.set_distribution! nil, nil
      flash[:info] = I18n.t('order_cycles_closed_for_hub')
      redirect_to main_app.root_url
    end
  end

  def current_distributor_closed?
    current_distributor &&
      current_order &&
      current_distributor.respond_to?(:ready_for_checkout?) &&
      !current_distributor.ready_for_checkout?
  end

  def check_order_cycle_expiry
    if current_order_cycle.andand.closed?
      current_order.empty!
      current_order.set_order_cycle! nil
      flash[:info] = I18n.t('order_cycle_closed')
      redirect_to main_app.root_url
    end
  end

  # All render calls within the block will be performed with the specified format
  # Useful for rendering html within a JSON response, particularly if the specified
  # template or partial then goes on to render further partials without specifying
  # their format.
  def with_format(format)
    old_formats = formats
    self.formats = [format]
    yield
    self.formats = old_formats
    nil
  end

  # See https://jacopretorius.net/2014/01/force-page-to-reload-on-browser-back-in-rails.html
  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end

require 'spree/i18n/initializer'
