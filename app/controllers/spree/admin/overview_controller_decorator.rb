Spree::Admin::OverviewController.class_eval do
  def index
    @enterprises = Enterprise.managed_by(spree_current_user).order('is_distributor DESC, is_primary_producer ASC, name')
    @product_count = Spree::Product.active.managed_by(spree_current_user).count
    @order_cycle_count = OrderCycle.active.managed_by(spree_current_user).count
  end

  # This is in Spree::Core::ControllerHelpers::Auth
  # But you can't easily reopen modules in Ruby
  def unauthorized
    if try_spree_current_user
      flash[:error] = t(:authorization_failure)
      redirect_to '/unauthorized'
    else
      store_location
      redirect_to root_path(anchor: "login?after_login=#{spree.admin_path}")
    end
  end
end
