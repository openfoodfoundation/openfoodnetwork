module Admin
  class ExchangesProductsController < Spree::Admin::BaseController
    def index
      @exchange = Exchange.find_by_id(params[:exchange_id])

      respond_to do |format|
        format.json do
          render json: exchange_products,
                 each_serializer: Api::Admin::ForOrderCycle::SuppliedProductSerializer,
                 order_cycle: @exchange.order_cycle
        end
      end
    end

    private

    # So far, products for incoming exchanges only
    def exchange_products
      return [] unless @exchange.incoming

      products_for_incoming_exchange
    end

    def products_for_incoming_exchange
      if @exchange.order_cycle.prefers_product_selection_from_coordinator_inventory_only?
        @exchange.sender.supplied_products.visible_for(@order_cycle.coordinator)
      else
        @exchange.sender.supplied_products
      end
    end
  end
end
