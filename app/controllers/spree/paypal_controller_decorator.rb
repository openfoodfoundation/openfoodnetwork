Spree::PaypalController.class_eval do
  include CheckoutHelper

  after_filter :reset_order_when_complete, only: :confirm

  def cancel
    flash[:notice] = t('flash.cancel', :scope => 'paypal')
    redirect_to main_app.checkout_path
  end


  private

  def reset_order_when_complete
    if current_order.complete?
      flash[:success] = t(:order_processed_successfully)
      reset_order
    end
  end
end
