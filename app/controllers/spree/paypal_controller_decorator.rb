Spree::PaypalController.class_eval do
  def cancel
    flash[:notice] = t('flash.cancel', :scope => 'paypal')
    redirect_to main_app.checkout_path
  end
end
