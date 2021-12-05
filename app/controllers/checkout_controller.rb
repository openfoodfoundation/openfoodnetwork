# frozen_string_literal: true

require 'open_food_network/address_finder'

class CheckoutController < ::BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include OrderCompletion

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

  before_action :ensure_order_not_completed
  before_action :ensure_checkout_allowed
  before_action :handle_insufficient_stock

  before_action :associate_user
  before_action :check_authorization
  before_action :enable_embedded_shopfront

  helper 'spree/orders'

  def edit
    return handle_redirect_from_stripe if valid_payment_intent_provided?

    # This is only required because of spree_paypal_express. If we implement
    # a version of paypal that uses this controller, and more specifically
    # the #action_failed method, then we can remove this call
    reset_order_to_cart
  rescue Spree::Core::GatewayError => e
    rescue_from_spree_gateway_error(e)
  end

  def update
    params_adapter = Checkout::FormDataAdapter.new(permitted_params, @order, spree_current_user)
    return action_failed unless @order.update(params_adapter.params[:order] || {})

    checkout_workflow(params_adapter.shipping_method_id)
  rescue Spree::Core::GatewayError => e
    rescue_from_spree_gateway_error(e)
  rescue StandardError => e
    flash[:error] = I18n.t("checkout.failed")
    action_failed(e)
  ensure
    @order.update_order!
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

  def load_order
    @order = current_order

    if order_invalid_for_checkout?
      Bugsnag.notify("Notice: invalid order loaded during Stripe processing", order: @order) if valid_payment_intent_provided?
      redirect_to(main_app.shop_path) && return
    end

    handle_invalid_stock && return unless valid_order_line_items?

    return if valid_payment_intent_provided?

    before_address
    setup_for_current_state
  end

  def order_invalid_for_checkout?
    !@order || @order.completed? || !@order.checkout_allowed?
  end

  def handle_invalid_stock
    cancel_incomplete_payments if valid_payment_intent_provided?
    reset_order_to_cart

    respond_to do |format|
      format.html do
        redirect_to main_app.cart_path
      end

      format.json do
        render json: { path: main_app.cart_path }, status: :bad_request
      end
    end
  end

  def cancel_incomplete_payments
    # The checkout could not complete due to stock running out. We void any pending (incomplete)
    # Stripe payments here as the order will need to be changed and resubmitted (or abandoned).
    @order.payments.incomplete.each do |payment|
      payment.void_transaction!
      payment.adjustment&.update_columns(eligible: false, state: "finalized")
    end
    flash[:notice] = I18n.t("checkout.payment_cancelled_due_to_stock")
  end

  def reset_order_to_cart
    OrderCheckoutRestart.new(@order).call
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
    @valid_payment_intent_provided ||= begin
      return false unless params["payment_intent"]&.starts_with?("pi_")

      last_payment = OrderPaymentFinder.new(@order).last_payment
      @order.state == "payment" &&
        last_payment&.state == "requires_authorization" &&
        last_payment&.response_code == params["payment_intent"]
    end
  end

  def handle_redirect_from_stripe
    return checkout_failed unless @order.process_payments!

    if OrderWorkflow.new(@order).next && order_complete?
      checkout_succeeded
      redirect_to order_path(@order)
    else
      checkout_failed
    end
  end

  def checkout_workflow(shipping_method_id)
    while @order.state != "complete"
      if @order.state == "payment"
        return if redirect_to_payment_gateway

        return action_failed if @order.errors.any?
        return action_failed unless @order.process_payments!
      end

      next if OrderWorkflow.new(@order).next({ "shipping_method_id" => shipping_method_id })

      return action_failed
    end

    update_response
  end

  def redirect_to_payment_gateway
    return unless selected_payment_method.external_gateway?
    return unless (redirect_url = selected_payment_method.external_payment_url(order: @order))

    render json: { path: redirect_url }, status: :ok
    true
  end

  def selected_payment_method
    @selected_payment_method ||= Spree::PaymentMethod.find(
      params.dig(:order, :payments_attributes, 0, :payment_method_id)
    )
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
    Checkout::PostCheckoutActions.new(@order).success(params, spree_current_user)

    order_completion_reset(@order)
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
    Bugsnag.notify(error, order: @order)
    flash[:error] = order_error if flash.blank?
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
