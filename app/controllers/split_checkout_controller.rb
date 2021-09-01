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
      redirect_to_step
    else
      flash.now[:error] = I18n.t('split_checkout.errors.global')
      render :edit
    end
  end

  private

  def clear_invalid_payments
    @order.payments.with_state(:invalid).delete_all
  end

  def confirm_order
    return unless @order.confirmation? && params[:confirm_order]
    return unless validate_terms_and_conditions!

    @order.confirm!
  end

  def update_order
    return if @order.errors.any?

    @order.update(order_params) && advance_order_state
  end

  def advance_order_state
    return true if @order.complete?

    OrderWorkflow.new(@order).advance_checkout(raw_params.slice(:shipping_method_id))
  end

  def checkout_step
    @checkout_step ||= params[:step]
  end

  def validate_terms_and_conditions!
    return true if params[:accept_terms]

    @order.errors.add(:terms_and_conditions, t("split_checkout.errors.terms_not_accepted"))
    false
  end

  def order_params
    @order_params ||= Checkout::Params.new(@order, params).call
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
