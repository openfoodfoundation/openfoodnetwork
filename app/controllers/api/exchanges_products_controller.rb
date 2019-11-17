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
      render json: exchange_products(@incoming, @enterprise),
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

    def exchange_products(incoming, enterprise)
      if incoming
        products_for_incoming_exchange(enterprise)
      else
        products_for_outgoing_exchange
      end
    end

    def products_for_incoming_exchange(enterprise)
      supplied_products(enterprise)
    end

    def supplied_products(enterprise)
      if @order_cycle.present? &&
         @order_cycle.prefers_product_selection_from_coordinator_inventory_only?
        enterprise.supplied_products.visible_for(@order_cycle.coordinator)
      else
        enterprise.supplied_products
      end
    end

    def products_for_outgoing_exchange
      products = []
      enterprises_for_outgoing_exchange.each do |enterprise|
        products.push( *supplied_products(enterprise).to_a )

        products.each do |product|
          unless product_supplied_to_order_cycle?(product)
            products.delete(product)
          end
        end
      end
      products
    end

    def product_supplied_to_order_cycle?(product)
      (product.variants.map(&:id) & incoming_exchanges_variants).any?
    end

    def incoming_exchanges_variants
      return @incoming_exchanges_variants if @incoming_exchanges_variants.present?

      @incoming_exchanges_variants = []
      visible_incoming_exchanges.each do |exchange|
        @incoming_exchanges_variants.push(
          *exchange.variants.merge(visible_incoming_variants(exchange)).map(&:id).to_a
        )
      end
      @incoming_exchanges_variants
    end

    def visible_incoming_exchanges
      OpenFoodNetwork::OrderCyclePermissions.
        new(spree_current_user, @order_cycle).
        visible_exchanges.
        by_enterprise_name.
        incoming
    end

    def visible_incoming_variants(exchange)
      if exchange.order_cycle.prefers_product_selection_from_coordinator_inventory_only?
        permitted_incoming_variants(exchange).visible_for(exchange.order_cycle.coordinator)
      else
        permitted_incoming_variants(exchange)
      end
    end

    def permitted_incoming_variants(exchange)
      OpenFoodNetwork::OrderCyclePermissions.new(spree_current_user, exchange.order_cycle).
        visible_variants_for_incoming_exchanges_from(exchange.sender)
    end

    def enterprises_for_outgoing_exchange
      enterprises = OpenFoodNetwork::OrderCyclePermissions.
        new(spree_current_user, @order_cycle)
        .visible_enterprises
      return enterprises if enterprises.empty?

      enterprises.includes(
        supplied_products: [:supplier, :variants, master: [:images]]
      )
    end
  end
end
