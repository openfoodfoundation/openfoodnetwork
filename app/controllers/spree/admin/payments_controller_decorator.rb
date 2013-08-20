# When a user fires an event, take them back to where they came from
# Responder: http://guides.spreecommerce.com/developer/logic.html#overriding-controller-action-responses

# For some strange reason, adding PaymentsController.class_eval will cause gems/spree/app/controllers/spree/admin/payments_controller.rb:37 to error:
#   payments_url not defined.
# This could be fixed by replacing line 37 with:
#   respond_with(@payment, location: admin_order_payments_url) { |format| format.html { redirect_to admin_order_payments_path(@order) } }


Spree::Admin::PaymentsController.class_eval do
  respond_override :fire => { :html => { :success => lambda {
    redirect_to request.referer  # Keeps any filter and sort prefs
  } } }
end
