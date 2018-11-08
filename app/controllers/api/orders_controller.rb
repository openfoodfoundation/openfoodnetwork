module Api
  class OrdersController < BaseController
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
  end
end
