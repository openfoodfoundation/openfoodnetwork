# If a user fires an event on a payment from the orders page, set the responder to takes you back to the orders page (not payments page)
#Responder: http://guides.spreecommerce.com/developer/logic.html#overriding-controller-action-responses

#TODO: for some reason this :fire responder kills the payments#create respond_with.. (core/app/controllers/spree/admin/payments_controller.rb:37)

Spree::Admin::PaymentsController.class_eval do
  respond_override :fire => { :html => { :success => lambda {
    redirect_to request.referer #keeps any filter and sort prefs
    
    #if request.referrer.path_parameters['controller'] == 'spree/admin/orders'
    #  redirect_to admin_orders_path
    #else
    #  redirect_to admin_order_payments_path(@order) #default action
    #end  
  } } }
end
