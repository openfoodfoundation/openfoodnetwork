module Api
  class ExchangesProductsController < Api::BaseController
    skip_authorization_check only: [:index]

    def index
      @exchange = Exchange.find_by_id(params[:exchange_id])

      render json: exchange_products,
             each_serializer: Api::Admin::ForOrderCycle::SuppliedProductSerializer,
             order_cycle: @exchange.order_cycle,
             status: :ok
    end

    private

    def exchange_products
      if @exchange.incoming
        products_for_incoming_exchange
      else
        products_for_outgoing_exchange
      end
    end

    def products_for_incoming_exchange
      supplied_products(@exchange.order_cycle, @exchange.sender)
    end

    def supplied_products(order_cycle, enterprise)
      if order_cycle.prefers_product_selection_from_coordinator_inventory_only?
        enterprise.supplied_products.visible_for(order_cycle.coordinator)
      else
        enterprise.supplied_products
      end
    end

    def products_for_outgoing_exchange
      products = []
      enterprises_for_outgoing_exchange.each do |enterprise|
        products.push( *supplied_products(@exchange.order_cycle, enterprise).to_a )

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

      scoped_exchanges =
        OpenFoodNetwork::OrderCyclePermissions.
          new(spree_current_user, @exchange.order_cycle).
          visible_exchanges.
          by_enterprise_name.
          incoming

      @incoming_exchanges_variants = []
      scoped_exchanges.each do |exchange|
        @incoming_exchanges_variants.push(
          *exchange.variants.merge(visible_incoming_variants(exchange)).map(&:id).to_a
        )
      end
      @incoming_exchanges_variants
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
        new(spree_current_user, @exchange.order_cycle)
        .visible_enterprises
      return enterprises if enterprises.empty?

      enterprises.includes(
        supplied_products: [:supplier, :variants, master: [:images]]
      )
    end
  end
end
