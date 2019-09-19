module Api
  class OrdersController < BaseController
    def show
      authorize! :read, order
      render json: order, serializer: Api::OrderDetailedSerializer
    end

    def index
      authorize! :admin, Spree::Order

      search_results = SearchOrders.new(params, spree_current_user)

      render json: {
        orders: serialized_orders(search_results.orders),
        pagination: search_results.pagination_data
      }
    end

    private

    def serialized_orders(orders)
      ActiveModel::ArraySerializer.new(
        orders,
        each_serializer: Api::Admin::OrderSerializer
      )
    end

    def order
      @order ||= Spree::Order.find_by_number!(params[:id])
    end
  end
end
