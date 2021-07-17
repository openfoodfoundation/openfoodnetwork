class SplitCheckoutController < CheckoutController
  def edit
    redirect_to_step if request.path == "/checkout"
    super
  end

  def update
    params_adapter = Checkout::FormDataAdapter.new(permitted_params, @order, spree_current_user)
    return action_failed unless @order.update(params_adapter.params[:order] || {})

    checkout_workflow(params_adapter.shipping_method_id, params[:advance_to_state] || "delivery")
  rescue Spree::Core::GatewayError => e
    rescue_from_spree_gateway_error(e)
  rescue StandardError => e
    flash[:error] = I18n.t("checkout.failed")
    action_failed(e)
  ensure
    @order.update_order!
  end

  private

  def redirect_to_step
    if @order.state = "payment"
      if @order.payment_method_id.nil?
        redirect_to checkout_payment_method_path
      else
        redirect_to  checkout_order_summary_path
      end
    elsif @order.state == "cart"
      redirect_to checkout_your_details_path
    end
  end

  def redirect_to_payment_gateway
    return unless params&.dig(:order)&.dig(:payments_attributes)&.first&.dig(:payments_attributes)

    super
  end

  def update_response
    redirect_to checkout_payment_method_path
  end
end
