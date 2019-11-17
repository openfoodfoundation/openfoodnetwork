module Api
  class ExchangesProductsController < Api::BaseController
    skip_authorization_check only: [:index, :show]

    # Lists products for an Enterprise in an Order Cycle
    #   This is the same as index below but when the Exchange doesn't exist yet
    #
    #   Parameters are: enterprise_id, order_cycle_id and incoming
    #     order_cycle_id is optional if for incoming
    def show
      load_data_from_params

      render_products
    end

    # Lists products in an Exchange
    def index
      load_data_from_exchange

      render_products
    end

    private

    def render_products
      products = ExchangeProductsRenderer.
        new(@order_cycle, spree_current_user).
        exchange_products(@incoming, @enterprise)

      render json: products,
             each_serializer: Api::Admin::ForOrderCycle::SuppliedProductSerializer,
             order_cycle: @order_cycle,
             status: :ok
    end

    def load_data_from_exchange
      exchange = Exchange.find_by_id(params[:exchange_id])

      @order_cycle = exchange.order_cycle
      @incoming = exchange.incoming
      @enterprise = exchange.sender
    end

    def load_data_from_params
      @enterprise = Enterprise.find_by_id(params[:enterprise_id])

      if params[:order_cycle_id]
        @order_cycle = OrderCycle.find_by_id(params[:order_cycle_id])
      elsif !params[:incoming]
        raise "order_cycle_id is required to list products for new outgoing exchange"
      end
      @incoming = params[:incoming]
    end
  end
end
