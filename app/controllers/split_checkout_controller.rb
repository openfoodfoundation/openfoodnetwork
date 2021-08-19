# frozen_string_literal: true

require 'open_food_network/address_finder'

class SplitCheckoutController < ::BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include Spree::BaseHelper
  include CheckoutCallbacks

  helper 'terms_and_conditions'
  helper 'checkout'
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
      clear_invalid_payments
      advance_order_state
      redirect_to_step
    else
      flash.now[:error] = "Saving failed, please update the highlighted fields"
      render :edit
    end
  end

  private

  def clear_invalid_payments
    @order.payments.with_state(:invalid).delete_all
  end

  def confirm_order
    return unless @order.confirmation? && params[:confirm_order]

    @order.confirm!
  end

  def update_order
    return unless params[:order]
    return if @order.state == "address" && params[:shipping_method_id].blank?

    @order.update(order_params)
  end

  def advance_order_state
    return if @order.complete?

    workflow_options = raw_params.slice(:shipping_method_id)

    OrderWorkflow.new(@order).advance_to_confirmation(workflow_options)
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

  def order_complete?
    @order.state == "complete" || @order.completed?
  end

  def rescue_from_spree_gateway_error(error)
    flash[:error] = t(:spree_gateway_error_flash_for_checkout, error: error.message)
    action_failed(error)
  end
end
