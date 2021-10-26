# frozen_string_literal: true

require 'open_food_network/address_finder'

class SplitCheckoutController < ::BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include Spree::BaseHelper
  include CheckoutCallbacks
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
      clear_invalid_payments
      advance_order_state
      redirect_to_step
    else
      flash.now[:error] = I18n.t('split_checkout.errors.global')

      render operations: cable_car.
        replace("#checkout", partial("split_checkout/checkout")).
        replace("#flashes", partial("shared/flashes", locals: { flashes: flash })),
             status: :unprocessable_entity
    end
  end

  private

  def clear_invalid_payments
    @order.payments.with_state(:invalid).delete_all
  end

  def confirm_order
    return unless @order.confirmation? && params[:confirm_order]
    return unless validate_summary! && @order.errors.empty?

    @order.confirm!
  end

  def update_order
    return if @order.errors.any?

    @order.select_shipping_method(params[:shipping_method_id])
    @order.update(order_params)
    send("validate_#{params[:step]}!")

    @order.errors.empty?
  end

  def advance_order_state
    return if @order.complete?

    OrderWorkflow.new(@order).advance_checkout(raw_params.slice(:shipping_method_id))
  end

  def validate_details!
    return true if params[:shipping_method_id].present?

    @order.errors.add :shipping_method, I18n.t('split_checkout.errors.select_a_shipping_method')
  end

  def validate_payment!
    return true if params.dig(:order, :payments_attributes).present?

    @order.errors.add :payment_method, I18n.t('split_checkout.errors.select_a_payment_method')
  end

  def validate_summary!
    return true if params[:accept_terms]

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
