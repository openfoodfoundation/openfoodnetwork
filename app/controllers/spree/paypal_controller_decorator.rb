Spree::PaypalController.class_eval do
  before_filter :enable_embedded_shopfront
  before_filter :destroy_orphaned_paypal_payments, only: :confirm
  after_filter :reset_order_when_complete, only: :confirm

  def cancel
    flash[:notice] = Spree.t('flash.cancel', :scope => 'paypal')
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
      flash[:notice] = t(:order_processed_successfully)

      ResetOrderService.new(self, current_order).call
      session[:access_token] = current_order.token
    end
  end

  # See #1074 and #1837 for more detail on why we need this
  # An 'orphaned' Spree::Payment is created for every call to CheckoutController#update
  # for orders that are processed using a Spree::Gateway::PayPalExpress payment method
  # These payments are 'orphaned' because they are never used by the spree_paypal_express gem
  # which creates a brand new Spree::Payment from scratch in PayPalController#confirm
  # However, the 'orphaned' payments are useful when applying a transaction fee, because the fees
  # need to be calculated before the order details are sent to PayPal for confirmation
  # This is our best hook for removing the orphaned payments at an appropriate time. ie. after
  # the payment details have been confirmed, but before any payments have been processed
  def destroy_orphaned_paypal_payments
    return unless payment_method.is_a?(Spree::Gateway::PayPalExpress)
    orphaned_payments = current_order.payments.where(payment_method_id: payment_method.id, source_id: nil)
    orphaned_payments.each(&:destroy)
  end
end
