Spree::Admin::OverviewController.class_eval do
  def index
    # TODO was sorted with is_distributor DESC as well, not sure why or how we want ot sort this now
    @enterprises = Enterprise.managed_by(spree_current_user).order('is_primary_producer ASC, name')
    @product_count = Spree::Product.active.managed_by(spree_current_user).count
    @order_cycle_count = OrderCycle.active.managed_by(spree_current_user).count

    unspecified = spree_current_user.owned_enterprises.where(sells: 'unspecified')
    outside_referral = !URI(request.referer.to_s).path.match(/^\/admin/)

    if OpenFoodNetwork::Permissions.new(spree_current_user).manages_one_enterprise? && !spree_current_user.admin?
      @enterprise = @enterprises.first
      if outside_referral && unspecified.any?
        redirect_to main_app.welcome_admin_enterprise_path(@enterprise)
      else
        render "single_enterprise_dashboard"
      end
    else
      if outside_referral && unspecified.any?
        redirect_to main_app.admin_enterprises_path
      else
        render "multi_enterprise_dashboard"
      end
    end
  end
end
