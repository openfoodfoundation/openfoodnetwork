# If a user fires an event on a payment from the orders page, set the responder to takes you back to the orders page (not payments page)
#Responder: http://guides.spreecommerce.com/developer/logic.html#overriding-controller-action-responses

Spree::Admin::PaymentsController.class_eval do
  respond_override :fire => { :html => { :success => lambda {
      #if referrer == orders#index
      #  redirect_to orders#index
    } } }
end
