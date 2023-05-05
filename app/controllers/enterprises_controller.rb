# frozen_string_literal: true

require 'open_food_network/enterprise_injection_data'

class EnterprisesController < BaseController
  layout "darkswarm"
  include OrderCyclesHelper
  include SerializerHelper
  include WhiteLabel

  protect_from_forgery except: :check_permalink

  # These prepended filters are in the reverse order of execution
  prepend_before_action :set_order_cycles, :require_distributor_chosen, :reset_order, only: :shop

  before_action :clean_permalink, only: :check_permalink
  before_action :hide_ofn_navigation, only: :shop

  respond_to :js, only: :permalink_checker

  def shop
    return redirect_to main_app.cart_path unless enough_stock?

    set_noindex_meta_tag

    @enterprise = current_distributor
  end

  def relatives
    set_enterprise

    respond_to do |format|
      format.json do
        enterprises = @enterprise&.relatives&.activated
        render(json: enterprises,
               each_serializer: Api::EnterpriseSerializer,
               data: OpenFoodNetwork::EnterpriseInjectionData.new)
      end
    end
  end

  def check_permalink
    if Enterprise.find_by permalink: params[:permalink]
      render(plain: params[:permalink], status: :conflict) && return
    end

    begin
      Rails.application.routes.recognize_path( "/#{params[:permalink]}" )
      render plain: params[:permalink], status: :conflict
    rescue ActionController::RoutingError
      render plain: params[:permalink], status: :ok
    end
  end

  private

  def set_enterprise
    @enterprise = Enterprise.find_by(id: params[:id])
  end

  def clean_permalink
    params[:permalink] = params[:permalink].parameterize
  end

  def enough_stock?
    current_order(true).insufficient_stock_lines.blank?
  end

  def reset_order
    order = current_order(true)

    # reset_distributor must be called before any call to current_customer or current_distributor
    order_cart_reset = OrderCartReset.new(order, params[:id])
    order_cart_reset.reset_distributor
    order_cart_reset.reset_other!(spree_current_user, current_customer)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = I18n.t(:enterprise_shop_show_error)
    redirect_to shops_path
  end

  def set_noindex_meta_tag
    @noindex_meta_tag = true unless current_distributor.visible?
  end
end
