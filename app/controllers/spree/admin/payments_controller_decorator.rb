# When a user fires an event, take them back to where they came from
# Responder: http://guides.spreecommerce.com/developer/logic.html#overriding-controller-action-responses

Spree::Admin::PaymentsController.class_eval do
  respond_override :fire => { :html => { :success => lambda {
    redirect_to request.referer  # Keeps any filter and sort prefs
  } } }
end
