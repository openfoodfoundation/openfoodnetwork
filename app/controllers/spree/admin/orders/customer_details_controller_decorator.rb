Spree::Admin::Orders::CustomerDetailsController.class_eval do
  #Override BaseController.authorize_admin to inherit CanCan permissions for the current order
  def authorize_admin
      load_order unless @order
      authorize! :admin, @order
      authorize! params[:action].to_sym, @order
  end
end