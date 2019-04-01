require 'open_food_network/address_finder'

class Spree::CheckoutController < Spree::StoreController
  include CheckoutHelper

  before_filter :enable_embedded_shopfront

  ####################################
  #### Copied from Spree Frontend ####
  ####################################
  ssl_required

  before_filter :load_order

  before_filter :ensure_order_not_completed
  before_filter :ensure_checkout_allowed
  before_filter :ensure_sufficient_stock_lines

  before_filter :associate_user
  before_filter :check_authorization

  helper 'spree/orders'

  rescue_from Spree::Core::GatewayError, :with => :rescue_from_spree_gateway_error
  ####################################
  ####################################

  def edit
    flash.keep
    redirect_to main_app.checkout_path
  end

  private

  ####################################
  #### Copied from Spree Frontend ####
  ####################################
  def load_order
    @order = current_order
    redirect_to spree.cart_path and return unless @order

    if params[:state]
      redirect_to checkout_state_path(@order.state) if @order.can_go_to_state?(params[:state])
      @order.state = params[:state]
    end
    setup_for_current_state
  end

  def ensure_checkout_allowed
    unless @order.checkout_allowed?
      redirect_to spree.cart_path
    end
  end

  def ensure_order_not_completed
    redirect_to spree.cart_path if @order.completed?
  end

  def ensure_sufficient_stock_lines
    if @order.insufficient_stock_lines.present?
      flash[:error] = Spree.t(:inventory_error_flash_for_insufficient_quantity)
      redirect_to spree.cart_path
    end
  end

  # Provides a route to redirect after order completion
  def completion_route
    spree.order_path(@order)
  end

  def setup_for_current_state
    method_name = :"before_#{@order.state}"
    send(method_name) if respond_to?(method_name, true)
  end

  def before_delivery
    return if params[:order].present?

    packages = @order.shipments.map { |s| s.to_package }
    @differentiator = Spree::Stock::Differentiator.new(@order, packages)
  end

  def rescue_from_spree_gateway_error
    flash[:error] = Spree.t(:spree_gateway_error_flash_for_checkout)
    render :edit
  end

  def check_authorization
    authorize!(:edit, current_order, session[:access_token])
  end
  ####################################
  ####################################

  def before_payment
    current_order.payments.destroy_all if request.put?
  end

  # Adapted from spree_last_address gem: https://github.com/TylerRick/spree_last_address
  # Originally, we used a forked version of this gem, but encountered strange errors where
  # it worked in dev but only intermittently in staging/prod.
  def before_address
    associate_user

    finder = OpenFoodNetwork::AddressFinder.new(@order.email)

    @order.bill_address = finder.bill_address
    @order.ship_address = finder.ship_address
  end
end
