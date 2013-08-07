Spree::Admin::OrdersController.class_eval do
  respond_override :index => { :html =>
    { :success => lambda { 
      # Filter orders to only show those managed by current user
      @orders = @search.result.includes([:user, :shipments, :payments]).
        managed_by(spree_current_user).
        page(params[:page]).
        per(params[:per_page] || Spree::Config[:orders_per_page])
    } } }
end