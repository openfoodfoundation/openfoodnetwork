# frozen_string_literal: true

require 'open_food_network/address_finder'

class CheckoutController < ::BaseController
  include OrderStockCheck
  include OrderCompletion

  layout 'darkswarm'

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

  before_action :handle_insufficient_stock

  before_action :associate_user
  before_action :check_authorization

  helper 'spree/orders'

  def edit; end

  def update
    params_adapter = Checkout::FormDataAdapter.new(permitted_params, @order, spree_current_user)
    return action_failed unless @order.update(params_adapter.params[:order] || {})

    checkout_workflow(params_adapter.shipping_method_id)
  rescue Spree::Core::GatewayError => e
    gateway_error(e)
    action_failed(e)
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

  def load_order
    load_checkout_order

    return handle_invalid_stock unless valid_order_line_items?

    before_address
    setup_for_current_state
  end

  def handle_invalid_stock
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

  def checkout_workflow(shipping_method_id)
    while @order.state != "complete"
      if @order.state == "payment"
        update_payment_total
        return if redirect_to_payment_gateway

        return action_failed if @order.errors.any?
        return action_failed unless @order.process_payments!
      end

      next if OrderWorkflow.new(@order).next({ "shipping_method_id" => shipping_method_id })

      return action_failed
    end

    update_response
  end

  def update_payment_total
    @order.updater.update_totals
    @order.updater.update_pending_payment
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

  def update_response
    if order_complete?
      processing_succeeded
      update_succeeded_response
    else
      action_failed(RuntimeError.new("Order not complete after the checkout workflow"))
    end
  end

  def order_complete?
    @order.state == "complete" || @order.completed?
  end

  def update_succeeded_response
    respond_to do |format|
      format.html do
        respond_with(@order, location: order_completion_route)
      end
      format.json do
        render json: { path: order_completion_route }, status: :ok
      end
    end
  end

  def action_failed(error = RuntimeError.new(order_processing_error))
    processing_failed(error)
    action_failed_response
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
