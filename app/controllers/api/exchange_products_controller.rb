# This controller lists products that can be added to an exchange
module Api
  class ExchangeProductsController < Api::BaseController
    skip_authorization_check only: [:index]

    # If exchange_id is present in the URL:
    #   Lists Products that can be added to that Exchange
    #
    # If exchange_id is not present in the URL:
    #   Lists Products of the Enterprise given that can be added to the given Order Cycle
    #   In this case parameters are: enterprise_id, order_cycle_id and incoming
    #     (order_cycle_id is not necessary for incoming exchanges)
    def index
      if params[:exchange_id].present?
        load_data_from_exchange
      else
        load_data_from_other_params
      end

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

    def load_data_from_other_params
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
