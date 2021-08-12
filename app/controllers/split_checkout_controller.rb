# frozen_string_literal: true

require 'open_food_network/address_finder'

class SplitCheckoutController < ::BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include Spree::BaseHelper

  helper 'terms_and_conditions'
  helper 'checkout'

  # We need pessimistic locking to avoid race conditions.
  # Otherwise we fail on duplicate indexes or end up with negative stock.
  prepend_around_action CurrentOrderLocker, only: [:edit, :update]

  prepend_before_action :check_hub_ready_for_checkout
  prepend_before_action :check_order_cycle_expiry
  prepend_before_action :require_order_cycle
  prepend_before_action :require_distributor_chosen

  before_action :load_order
  before_action :load_shipping_methods, :load_countries, if: -> { checkout_step == "details"}

  before_action :ensure_order_not_completed
  before_action :ensure_checkout_allowed
  before_action :handle_insufficient_stock

  before_action :associate_user
  before_action :check_authorization
  before_action :enable_embedded_shopfront

  helper 'spree/orders'
  helper OrderHelper

  def edit
    return handle_redirect_from_stripe if valid_payment_intent_provided?

    redirect_to_step unless checkout_step

    OrderWorkflow.new(@order).next if @order.cart?

    # This is only required because of spree_paypal_express. If we implement
    # a version of paypal that uses this controller, and more specifically
    # the #action_failed method, then we can remove this call
    # OrderCheckoutRestart.new(@order).call
  rescue Spree::Core::GatewayError => e
    rescue_from_spree_gateway_error(e)
  end

  def update
    if confirm_order || update_order
      advance_order_state
      redirect_to_step
    else
      flash[:error] = "Saving failed, please update the highlighted fields"
      render :edit
    end
  end

  # Clears the cached order. Required for #current_order to return a new order
  # to serve as cart. See https://github.com/spree/spree/blob/1-3-stable/core/lib/spree/core/controller_helpers/order.rb#L14
  # for details.
  def expire_current_order
    session[:order_id] = nil
    @current_order = nil
  end

  private

  def confirm_order
    return unless @order.confirmation? && params[:confirm_order]

    @order.confirm!
  end

  def update_order
    return unless params[:order]

    @order.update(order_params)
  end

  def advance_order_state
    return if @order.confirmation? || @order.complete?

    OrderWorkflow.new(@order).advance_to_confirmation
  end

  def checkout_step
    @checkout_step ||= params[:step]
  end

  def order_params
    return @order_params unless @order_params.nil?

    @order_params = params.require(:order).permit(
      :email, :shipping_method_id, :special_instructions,
      bill_address_attributes: PermittedAttributes::Address.attributes,
      ship_address_attributes: PermittedAttributes::Address.attributes,
      payments_attributes: [:payment_method_id]
    )

    if @order_params[:payments_attributes]
      # Set payment amount
      @order_params[:payments_attributes].first[:amount] = @order.total
    end

    @order_params
  end

  def redirect_to_step
    case @order.state
    when "cart", "address", "delivery"
      redirect_to checkout_step_path(:details)
    when "payment"
      redirect_to checkout_step_path(:payment)
    when "confirmation"
      redirect_to checkout_step_path(:summary)
    else
      redirect_to order_path(@order)
    end
  end

  def check_authorization
    authorize!(:edit, current_order, session[:access_token])
  end

  def ensure_checkout_allowed
    redirect_to main_app.cart_path unless @order.checkout_allowed?
  end

  def ensure_order_not_completed
    redirect_to main_app.cart_path if @order.completed?
  end

  def load_shipping_methods
    @shipping_methods = Spree::ShippingMethod.for_distributor(@order.distributor).order(:name)
  end

  def load_countries
    @countries = available_countries.map { |c| [c.name, c.id] }
    @countries_with_states = available_countries.map { |c| [c.id, c.states.map { |s| [s.name, s.id] }] }
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

  def before_payment
    current_order.payments.destroy_all if request.put?
  end

  def valid_payment_intent_provided?
    return false unless params["payment_intent"]&.starts_with?("pi_")

    last_payment = OrderPaymentFinder.new(@order).last_payment
    @order.state == "payment" &&
      last_payment&.state == "requires_authorization" &&
      last_payment&.response_code == params["payment_intent"]
  end

  def handle_redirect_from_stripe
    return checkout_failed unless @order.process_payments!

    if OrderWorkflow.new(@order).next && order_complete?
      checkout_succeeded
      redirect_to(order_path(@order)) && return
    else
      checkout_failed
    end
  end

  def checkout_workflow(shipping_method_id)
    while @order.state != "complete"
      if @order.state == "payment"
        return if redirect_to_payment_gateway

        return action_failed unless @order.process_payments!
      end

      next if OrderWorkflow.new(@order).next({ shipping_method_id: shipping_method_id })

      return action_failed
    end

    update_response
  end

  def redirect_to_payment_gateway
    return unless params&.dig(:order)&.dig(:payments_attributes)&.first&.dig(:payments_attributes)

    redirect_path = Checkout::PaypalRedirect.new(params).path
    redirect_path = Checkout::StripeRedirect.new(params, @order).path if redirect_path.blank?
    return if redirect_path.blank?

    render json: { path: redirect_path }, status: :ok
    true
  end

  def order_error
    if @order.errors.present?
      @order.errors.full_messages.to_sentence
    else
      t(:payment_processing_failed)
    end
  end

  def update_response
    if order_complete?
      checkout_succeeded
      update_succeeded_response
    else
      action_failed(RuntimeError.new("Order not complete after the checkout workflow"))
    end
  end

  def order_complete?
    @order.state == "complete" || @order.completed?
  end

  def checkout_succeeded
    Checkout::PostCheckoutActions.new(@order).success(self, params, spree_current_user)

    session[:access_token] = current_order.token
    flash[:notice] = t(:order_processed_successfully)
  end

  def update_succeeded_response
    respond_to do |format|
      format.html do
        respond_with(@order, location: order_path(@order))
      end
      format.json do
        render json: { path: order_path(@order) }, status: :ok
      end
    end
  end

  def action_failed(error = RuntimeError.new(order_error))
    checkout_failed(error)
    action_failed_response
  end

  def checkout_failed(error = RuntimeError.new(order_error))
    Bugsnag.notify(error)
    Checkout::PostCheckoutActions.new(@order).failure
  end

  def action_failed_response
    respond_to do |format|
      format.html do
        render :edit
      end
      format.json do
        discard_flash_errors
        render json: { errors: @order.errors, flash: flash.to_hash }.to_json, status: :bad_request
      end
    end
  end

  def rescue_from_spree_gateway_error(error)
    flash[:error] = t(:spree_gateway_error_flash_for_checkout, error: error.message)
    action_failed(error)
  end

  def permitted_params
    PermittedAttributes::Checkout.new(params).call
  end

  def discard_flash_errors
    # Marks flash errors for deletion after the current action has completed.
    # This ensures flash errors generated during XHR requests are not persisted in the
    # session for longer than expected.
    flash.discard(:error)
  end
end
