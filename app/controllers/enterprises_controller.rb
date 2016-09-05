require 'open_food_network/enterprise_injection_data'

class EnterprisesController < BaseController
  layout "darkswarm"
  helper Spree::ProductsHelper
  include OrderCyclesHelper

  # These prepended filters are in the reverse order of execution
  prepend_before_filter :set_order_cycles, :require_distributor_chosen, :reset_order, only: :shop
  before_filter :check_stock_levels, only: :shop

  before_filter :clean_permalink, only: :check_permalink
  before_filter :enable_embedded_shopfront

  respond_to :js, only: :permalink_checker

  def relatives
    respond_to do |format|
      format.json do
        enterprise = Enterprise.find(params[:id])
        enterprises = enterprise.andand.relatives.andand.activated
        render(json: enterprises,
               each_serializer: Api::EnterpriseSerializer,
               data: OpenFoodNetwork::EnterpriseInjectionData.new)
      end
    end
  end

  def check_permalink
    render text: params[:permalink], status: 409 and return if Enterprise.find_by_permalink params[:permalink]

    begin
      Rails.application.routes.recognize_path( "/#{ params[:permalink].to_s }" )
      render text: params[:permalink], status: 409

    rescue ActionController::RoutingError
      render text: params[:permalink], status: 200
    end
  end


  def stripe_connect
    if params["code"]
      # Get the deets from Stripe

      stripe_account = StripeAccount.new(stripe_user_id: params["stripe_user_id"], stripe_publishable_key: params["stripe_publishable_key"], enterprise: self) 
      if stripe_account.save
        render_json stripe_account
      else
        render text "Failed to save Stripe token", status: 500
      end
    else
      render text params["error_description"], status: 500
    end
  end

  private

  def clean_permalink
    params[:permalink] = params[:permalink].parameterize
  end

  def check_stock_levels
    if current_order(true).insufficient_stock_lines.present?
      redirect_to spree.cart_path
    end
  end

  def reset_order
    distributor = Enterprise.is_distributor.find_by_permalink(params[:id]) || Enterprise.is_distributor.find(params[:id])
    order = current_order(true)

    reset_distributor(order, distributor)

    reset_user_and_customer(order) if try_spree_current_user

    reset_order_cycle(order, distributor)

    order.save!
  end

  def reset_distributor(order, distributor)
    if order.distributor && order.distributor != distributor
      order.empty!
      order.set_order_cycle! nil
    end
    order.distributor = distributor
  end

  def reset_user_and_customer(order)
    order.associate_user!(spree_current_user) if order.user.blank? || order.email.blank?
    order.send(:associate_customer) if order.customer.nil? # Only associates existing customers
  end

  def reset_order_cycle(order, distributor)
    order_cycle_options = OrderCycle.active.with_distributor(distributor)
    order.order_cycle = order_cycle_options.first if order_cycle_options.count == 1
  end
end
