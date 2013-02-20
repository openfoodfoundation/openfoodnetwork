Spree::CheckoutController.class_eval do
  def before_payment
    current_order.payments.destroy_all if request.put?
  end
end