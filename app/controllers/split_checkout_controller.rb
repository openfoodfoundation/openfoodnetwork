# frozen_string_literal: true

require 'open_food_network/address_finder'

class SplitCheckoutController < ::BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include Spree::BaseHelper
  include CheckoutCallbacks
  include CheckoutSteps
  include OrderCompletion
  include CablecarResponses
  include WhiteLabel

  helper 'terms_and_conditions'
  helper 'checkout'
  helper 'spree/orders'
  helper EnterprisesHelper
  helper OrderHelper

  before_action :set_checkout_redirect
  before_action :hide_ofn_navigation, only: [:edit, :update]

  def edit
    redirect_to_step_based_on_order unless params[:step]
    check_step if params[:step]

    return if available_shipping_methods.any?

    flash[:error] = I18n.t('split_checkout.errors.no_shipping_methods_available')
  end

  def update
    if confirm_order || update_order
      return if performed?

      check_payments_adjustments
      clear_invalid_payments
      advance_order_state
      redirect_to_step
    else
      render_error
    end
  rescue Spree::Core::GatewayError => e
    flash[:error] = I18n.t(:spree_gateway_error_flash_for_checkout, error: e.message)
    @order.update_column(:state, "payment")
    render cable_ready: cable_car.redirect_to(url: checkout_step_path(:payment))
  end

  private

  def render_error
    flash.now[:error] ||= I18n.t('split_checkout.errors.saving_failed')

    render status: :unprocessable_entity, cable_ready: cable_car.
      replace("#checkout", partial("split_checkout/checkout")).
      replace("#flashes", partial("shared/flashes", locals: { flashes: flash }))
  end

  def check_payments_adjustments
    @order.payments.each(&:ensure_correct_adjustment)
  end

  def clear_invalid_payments
    @order.payments.with_state(:invalid).delete_all
  end

  def confirm_order
    return unless summary_step? && @order.confirmation?
    return unless validate_current_step

    @order.customer.touch :terms_and_conditions_accepted_at

    return true if redirect_to_payment_gateway

    @order.process_payments!
    @order.confirm!
    order_completion_reset @order
  end

  def redirect_to_payment_gateway
    return unless selected_payment_method&.external_gateway?
    return unless (redirect_url = selected_payment_method.external_payment_url(order: @order))

    render cable_ready: cable_car.redirect_to(url: redirect_url)
    true
  end

  def selected_payment_method
    @selected_payment_method ||= Checkout::PaymentMethodFetcher.new(@order).call
  end

  def update_order
    return if params[:confirm_order] || @order.errors.any?

    @order.select_shipping_method(params[:shipping_method_id])
    @order.update(order_params)
    @order.update_totals_and_states

    validate_current_step
  end

  def validate_current_step
    Checkout::Validation.new(@order, params).call && @order.errors.empty?
  end

  def advance_order_state
    return if @order.complete?

    OrderWorkflow.new(@order).advance_checkout(raw_params.slice(:shipping_method_id))
  end

  def order_params
    @order_params ||= Checkout::Params.new(@order, params, spree_current_user).call
  end
end
