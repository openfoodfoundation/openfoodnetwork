module Api
  class OrderCyclesController < Spree::Api::BaseController
    respond_to :json
    def managed
      @order_cycles = OrderCycle.ransack(params[:q]).result.managed_by(current_api_user)
      render params[:template] || :bulk_index
    end

    def accessible
      @order_cycles = OrderCycle.ransack(params[:q]).result.accessible_by(current_api_user)
      render params[:template] || :bulk_index
    end
  end
end
        