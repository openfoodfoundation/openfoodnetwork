Spree::PaypalController.class_eval do
  after_filter :reset_order_when_complete, only: :confirm
  before_filter :enable_embedded_shopfront

  def cancel
    flash[:notice] = t('flash.cancel', :scope => 'paypal')
    redirect_to main_app.checkout_path
  end

  # Clears the cached order. Required for #current_order to return a new order
  # to serve as cart. See https://github.com/spree/spree/blob/1-3-stable/core/lib/spree/core/controller_helpers/order.rb#L14
  # for details.
  def expire_current_order
    session[:order_id] = nil
    @current_order = nil
  end

  private

  def reset_order_when_complete
    if current_order.complete?
      flash[:success] = t(:order_processed_successfully)

      ResetOrderService.new(self, current_order).call
      session[:access_token] = current_order.token
    end
  end
end
