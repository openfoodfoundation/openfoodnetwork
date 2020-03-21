# frozen_string_literal: true

require 'open_food_network/address_finder'

class CheckoutController < Spree::StoreController
  layout 'darkswarm'

  include CheckoutHelper
  include OrderCyclesHelper
  include EnterprisesHelper

  ssl_required

  # We need pessimistic locking to avoid race conditions.
  # Otherwise we fail on duplicate indexes or end up with negative stock.
  prepend_around_filter CurrentOrderLocker, only: :update

  prepend_before_filter :check_hub_ready_for_checkout
  prepend_before_filter :check_order_cycle_expiry
  prepend_before_filter :require_order_cycle
  prepend_before_filter :require_distributor_chosen

  before_filter :load_order

  before_filter :ensure_order_not_completed
  before_filter :ensure_checkout_allowed
  before_filter :ensure_sufficient_stock_lines

  before_filter :associate_user
  before_filter :check_authorization
  before_filter :enable_embedded_shopfront

  helper 'spree/orders'

  rescue_from Spree::Core::GatewayError, with: :rescue_from_spree_gateway_error

  def edit
    # This is only required because of spree_paypal_express. If we implement
    # a version of paypal that uses this controller, and more specifically
    # the #update_failed method, then we can remove this call
    RestartCheckout.new(@order).call
  end

  def update
    params_adapter = Checkout::FormDataAdapter.new(permitted_params, @order, spree_current_user)
    return update_failed unless @order.update_attributes(params_adapter.params[:order])

    fire_event('spree.checkout.update')

    checkout_workflow(params_adapter.shipping_method_id)
  rescue Spree::Core::GatewayError => e
    rescue_from_spree_gateway_error(e)
  rescue StandardError => e
    Bugsnag.notify(e)
    flash[:error] = I18n.t("checkout.failed")
    update_failed
  end

  # Clears the cached order. Required for #current_order to return a new order
  # to serve as cart. See https://github.com/spree/spree/blob/1-3-stable/core/lib/spree/core/controller_helpers/order.rb#L14
  # for details.
  def expire_current_order
    session[:order_id] = nil
    @current_order = nil
  end

  private

  def check_authorization
    authorize!(:edit, current_order, session[:access_token])
  end

  def ensure_checkout_allowed
    redirect_to main_app.cart_path unless @order.checkout_allowed?
  end

  def ensure_order_not_completed
    redirect_to main_app.cart_path if @order.completed?
  end

  def ensure_sufficient_stock_lines
    if @order.insufficient_stock_lines.present?
      flash[:error] = Spree.t(:inventory_error_flash_for_insufficient_quantity)
      redirect_to main_app.cart_path
    end
  end

  def load_order
    @order = current_order

    redirect_to(main_app.shop_path) && return if redirect_to_shop?
    redirect_to_cart_path && return unless valid_order_line_items?
    before_address
    setup_for_current_state
  end

  def redirect_to_shop?
    !@order ||
      !@order.checkout_allowed? ||
      @order.completed?
  end

  def valid_order_line_items?
    @order.insufficient_stock_lines.empty? &&
      OrderCycleDistributedVariants.new(@order.order_cycle, @order.distributor).
        distributes_order_variants?(@order)
  end

  def redirect_to_cart_path
    respond_to do |format|
      format.html do
        redirect_to main_app.cart_path
      end

      format.json do
        render json: { path: main_app.cart_path }, status: :bad_request
      end
    end
  end

  def setup_for_current_state
    method_name = :"before_#{@order.state}"
    __send__(method_name) if respond_to?(method_name, true)
  end

  def before_address
    associate_user

    finder = OpenFoodNetwork::AddressFinder.new(@order.email, @order.customer, spree_current_user)

    @order.bill_address = finder.bill_address
    @order.ship_address = finder.ship_address
  end

  def before_delivery
    return if params[:order].present?

    packages = @order.shipments.map(&:to_package)
    @differentiator = Spree::Stock::Differentiator.new(@order, packages)
  end

  def before_payment
    current_order.payments.destroy_all if request.put?
  end

  def rescue_from_spree_gateway_error(error)
    flash[:error] = t(:spree_gateway_error_flash_for_checkout, error: error.message)
    respond_to do |format|
      format.html { render :edit }
      format.json { render json: { flash: flash.to_hash }, status: :bad_request }
    end
  end

  def checkout_workflow(shipping_method_id)
    while @order.state != "complete"
      if @order.state == "payment"
        return if redirect_to_payment_gateway
      end

      @order.select_shipping_method(shipping_method_id) if @order.state == "delivery"

      next if advance_order_state(@order)

      flash[:error] = order_workflow_error
      return update_failed
    end

    update_result
  end

  def redirect_to_payment_gateway
    redirect_path = Checkout::PaymentRedirect.new(params).path
    return if redirect_path.blank?

    render json: { path: redirect_path }, status: :ok
    true
  end

  # Perform order.next, guarding against StaleObjectErrors
  def advance_order_state(order)
    tries ||= 3
    order.next
  rescue ActiveRecord::StaleObjectError
    retry unless (tries -= 1).zero?
    false
  end

  def order_workflow_error
    if @order.errors.present?
      @order.errors.full_messages.to_sentence
    else
      t(:payment_processing_failed)
    end
  end

  def update_result
    if @order.state == "complete" || @order.completed?
      save_order_addresses_as_user_default
      ResetOrderService.new(self, current_order).call

      update_succeeded
    else
      update_failed
    end
  end

  def save_order_addresses_as_user_default
    user_default_address_setter = UserDefaultAddressSetter.new(@order, spree_current_user)
    user_default_address_setter.set_default_bill_address if params[:order][:default_bill_address]
    user_default_address_setter.set_default_ship_address if params[:order][:default_ship_address]
  end

  def update_succeeded
    session[:access_token] = current_order.token
    flash[:notice] = t(:order_processed_successfully)

    respond_to do |format|
      format.html do
        respond_with(@order, location: order_path(@order))
      end
      format.json do
        render json: { path: order_path(@order) }, status: :ok
      end
    end
  end

  def update_failed
    current_order.updater.shipping_address_from_distributor
    RestartCheckout.new(@order).call

    respond_to do |format|
      format.html do
        render :edit
      end
      format.json do
        render json: { errors: @order.errors, flash: flash.to_hash }.to_json, status: :bad_request
      end
    end
  end

  def permitted_params
    PermittedAttributes::Checkout.new(params).call
  end
end
