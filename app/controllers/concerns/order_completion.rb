# frozen_string_literal: true

module OrderCompletion
  extend ActiveSupport::Concern

  def order_completion_reset(order)
    distributor = order.distributor
    token = order.token

    expire_current_order
    build_new_order(distributor, token)

    session[:access_token] = current_order.token
    flash[:notice] = t(:order_processed_successfully)
  end

  private

  # Clears the cached order. Required for #current_order to return a new order to serve as cart.
  # See https://github.com/spree/spree/blob/1-3-stable/core/lib/spree/core/controller_helpers/order.rb#L14
  def expire_current_order
    session[:order_id] = nil
    @current_order = nil
  end

  # Builds an order setting the token and distributor of the one specified
  def build_new_order(distributor, token)
    new_order = current_order(true)
    new_order.set_distributor!(distributor)
    new_order.tokenized_permission.token = token
    new_order.tokenized_permission.save!
  end

  def load_checkout_order
    @order = current_order

    order_invalid! if order_invalid_for_checkout?
  end

  def order_completion_route
    main_app.order_path(@order, order_token: @order.token)
  end

  def order_failed_route(step: 'details')
    main_app.checkout_step_path(step:)
  end

  def order_invalid_for_checkout?
    !@order || @order.completed? || !@order.checkout_allowed?
  end

  def order_invalid!
    Bugsnag.notify("Notice: invalid order loaded during checkout") do |payload|
      payload.add_metadata :order, :order, @order
    end

    flash[:error] = t('checkout.order_not_loaded')
    redirect_to main_app.shop_path
  end

  def process_payment_completion!
    unless @order.process_payments!
      payment_failed
      return redirect_to order_failed_route(step: 'payment')
    end

    if Orders::WorkflowService.new(@order).next && @order.complete?
      processing_succeeded
      redirect_to order_completion_route
    else
      processing_failed
      redirect_to order_failed_route
    end
  rescue Spree::Core::GatewayError => e
    gateway_error(e)
    processing_failed
    redirect_to order_failed_route
  end

  def processing_succeeded
    Checkout::PostCheckoutActions.new(@order).success(params, spree_current_user)
    order_completion_reset(@order)
  end

  def payment_failed
    notify_failure
  end

  def processing_failed
    notify_failure
    Checkout::PostCheckoutActions.new(@order).failure
  end

  def notify_failure(error = RuntimeError.new(order_processing_error))
    Bugsnag.notify(error) do |payload|
      payload.add_metadata :order, @order
    end
    flash[:error] = order_processing_error if flash.blank?
  end

  def order_processing_error
    return t(:payment_processing_failed) if @order.errors.blank?

    @order.errors.full_messages.to_sentence
  end

  def gateway_error(error)
    flash[:error] = t(:spree_gateway_error_flash_for_checkout, error: error.message)
  end
end
