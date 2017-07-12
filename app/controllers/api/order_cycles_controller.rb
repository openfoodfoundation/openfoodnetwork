module Api
  class OrderCyclesController < Spree::Api::BaseController
    respond_to :json
    def managed
      authorize! :admin, OrderCycle
      authorize! :read, OrderCycle
      @order_cycles = OrderCycle.ransack(params[:q]).result.managed_by(current_api_user)
      render params[:template] || :bulk_index
    end

    def accessible
      @order_cycles = if params[:as] == "distributor"
        OrderCycle.ransack(params[:q]).result.
          involving_managed_distributors_of(current_api_user).order('updated_at DESC')
      elsif params[:as] == "producer"
        OrderCycle.ransack(params[:q]).result.
          involving_managed_producers_of(current_api_user).order('updated_at DESC')
      else
        OrderCycle.ransack(params[:q]).result.accessible_by(current_api_user)
      end

      render params[:template] || :bulk_index
    end
  end
end
