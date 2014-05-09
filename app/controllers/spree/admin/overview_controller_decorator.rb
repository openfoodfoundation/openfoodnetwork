module Spree
  module Admin
    class OverviewController < Spree::Admin::BaseController
      def index
        @enterprises = Enterprise.managed_by(spree_current_user).order('is_distributor DESC, is_primary_producer ASC, name')
        @product_count = Spree::Product.active.managed_by(spree_current_user).count
        @order_cycle_count = OrderCycle.active.managed_by(spree_current_user).count
      end
    end
  end
end