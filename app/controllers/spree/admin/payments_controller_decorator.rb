# When a user fires an event, take them back to where they came from
#Responder: http://guides.spreecommerce.com/developer/logic.html#overriding-controller-action-responses

Spree::Admin::PaymentsController.class_eval do
  respond_override :fire => { :html => { :success => lambda {
    redirect_to request.referer #keeps any filter and sort prefs
    
    #if request.referrer.path_parameters['controller'] == spree.admin_orders_path
    # redirect_to spree.admin_orders_path
    #else
    # redirect_to spree.admin_order_payments_path(@order) #default action
    #end  
  } } }
end
