# frozen_string_literal: true

require 'open_food_network/address_finder'

class SplitCheckoutController < ::BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include Spree::BaseHelper
  include CheckoutCallbacks
  include OrderCompletion
  include CablecarResponses

  helper 'terms_and_conditions'
  helper 'checkout'
  helper 'spree/orders'
  helper OrderHelper

  def edit
    redirect_to_step unless params[:step]
  end

  def update
    if confirm_order || update_order
      return if performed?

      clear_invalid_payments
      advance_order_state
      redirect_to_step
    else
      flash.now[:error] = I18n.t('split_checkout.errors.global')

      render status: :unprocessable_entity, operations: cable_car.
        replace("#checkout", partial("split_checkout/checkout")).
        replace("#flashes", partial("shared/flashes", locals: { flashes: flash }))
    end
  end

  private

  def clear_invalid_payments
    @order.payments.with_state(:invalid).delete_all
  end

  def confirm_order
    return unless summary_step? && @order.confirmation?
    return unless validate_summary! && @order.errors.empty?

    @order.customer.touch :terms_and_conditions_accepted_at

    return true if redirect_to_payment_gateway

    @order.confirm!
    order_completion_reset @order
  end

  def redirect_to_payment_gateway
    return unless selected_payment_method&.external_gateway?
    return unless (redirect_url = selected_payment_method.external_payment_url(order: @order))

    render operations: cable_car.redirect_to(url: URI(redirect_url))
    true
  end

  def selected_payment_method
    @selected_payment_method ||= @order.payments.order(:created_at).last&.payment_method
  end

  def update_order
    return if params[:confirm_order] || @order.errors.any?

    @order.select_shipping_method(params[:shipping_method_id])
    @order.update(order_params)

    validate_current_step!

    @order.errors.empty?
  end

  def summary_step?
    params[:step] == "summary"
  end

  def advance_order_state
    return if @order.complete?

    OrderWorkflow.new(@order).advance_checkout(raw_params.slice(:shipping_method_id))
  end

  def validate_current_step!
    step = ([params[:step]] & ["details", "payment", "summary"]).first
    send("validate_#{step}!")
  end

  def validate_details!
    return true if params[:shipping_method_id].present?

    @order.errors.add :shipping_method, I18n.t('split_checkout.errors.select_a_shipping_method')
  end

  def validate_payment!
    return true if params.dig(:order, :payments_attributes, 0, :payment_method_id).present?

    @order.errors.add :payment_method, I18n.t('split_checkout.errors.select_a_payment_method')
  end

  def validate_summary!
    return true if params[:accept_terms]
    return true unless TermsOfService.required?(@order.distributor)

    @order.errors.add(:terms_and_conditions, t("split_checkout.errors.terms_not_accepted"))
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
end
