Spree::Admin::OrdersController.class_eval do
  respond_override :index => { :html =>
    { :success => lambda { 
      # Filter orders to only show those distributed by current user (or all for admin user)
      @orders = @search.result.includes([:user, :shipments, :payments]).
        distributed_by_user(spree_current_user).
        page(params[:page]).
        per(params[:per_page] || Spree::Config[:orders_per_page])
    } } }
end