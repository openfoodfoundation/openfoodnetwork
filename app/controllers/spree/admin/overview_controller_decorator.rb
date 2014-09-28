Spree::Admin::OverviewController.class_eval do
  def index
    # TODO was sorted with is_distributor DESC as well, not sure why or how we want ot sort this now
    @enterprises = Enterprise.managed_by(spree_current_user).order('is_primary_producer ASC, name')
    @product_count = Spree::Product.active.managed_by(spree_current_user).count
    @order_cycle_count = OrderCycle.active.managed_by(spree_current_user).count
  end
end

