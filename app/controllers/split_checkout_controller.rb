class SplitCheckoutController < CheckoutController
  def update
    byebug
    params_adapter = Checkout::FormDataAdapter.new(permitted_params, @order, spree_current_user)
    return action_failed unless @order.update(params_adapter.params[:order] || {})

    checkout_workflow(params_adapter.shipping_method_id, params[:advance_to_state] || "delivery")
  rescue Spree::Core::GatewayError => e
    byebug
    rescue_from_spree_gateway_error(e)
  rescue StandardError => e
    byebug
    flash[:error] = I18n.t("checkout.failed")
    action_failed(e)
  ensure
    @order.update_order!
  end

  private

  def redirect_to_payment_gateway
    return unless params&.dig(:order)&.dig(:payments_attributes)&.first&.dig(:payments_attributes)

    super
  end
end
