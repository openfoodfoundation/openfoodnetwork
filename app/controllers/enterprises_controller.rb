class EnterprisesController < BaseController
  layout "darkswarm"
  helper Spree::ProductsHelper
  include OrderCyclesHelper

  # These prepended filters are in the reverse order of execution
  prepend_before_filter :set_order_cycles, :require_distributor_chosen, :reset_order, only: :shop
  before_filter :check_stock_levels, only: :shop

  before_filter :clean_permalink, only: :check_permalink

  respond_to :js, only: :permalink_checker


  def check_permalink
    return render text: params[:permalink], status: 409 if Enterprise.find_by_permalink params[:permalink]

    path = Rails.application.routes.recognize_path( "/#{ params[:permalink].to_s }" )
    if path && path[:controller] == "cms_content"
      render text: params[:permalink], status: 200
    else
      render text: params[:permalink], status: 409
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
