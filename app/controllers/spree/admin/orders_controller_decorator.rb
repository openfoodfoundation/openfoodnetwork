Spree::Admin::OrdersController.class_eval do
  before_filter :load_spree_api_key, :only => :bulk_management

  # We need to add expections for collection actions other than :index here
  # because spree_auth_devise causes load_order to be called, which results
  # in an auth failure as the @order object is nil for collection actions
  before_filter :check_authorization, :except => :bulk_management

  respond_override :index => { :html =>
    { :success => lambda { 
      # Filter orders to only show those distributed by current user (or all for admin user)
      @orders = @search.result.includes([:user, :shipments, :payments]).
        distributed_by_user(spree_current_user).
        page(params[:page]).
        per(params[:per_page] || Spree::Config[:orders_per_page])
    } } }

  private

  def load_spree_api_key
    current_user.generate_spree_api_key! unless spree_current_user.spree_api_key
    @spree_api_key = spree_current_user.spree_api_key
  end
end
