# This controller lists products that can be added to an exchange
module Api
  class ExchangeProductsController < Api::BaseController
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 100

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

      render_variant_count && return if params[:action_name] == "variant_count"

      render_paginated_products paginated_products
    end

    private

    def render_variant_count
      render text: {
        count: Spree::Variant.
          not_master.
          where(product_id: products).
          count
      }.to_json
    end

    def products
      ExchangeProductsRenderer.
        new(@order_cycle, spree_current_user).
        exchange_products(@incoming, @enterprise)
    end

    def paginated_products
      products.
        page(params[:page] || DEFAULT_PAGE).
        per(params[:per_page] || DEFAULT_PER_PAGE)
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

    def render_paginated_products(paginated_products)
      serializer = ActiveModel::ArraySerializer.new(
        paginated_products,
        each_serializer: Api::Admin::ForOrderCycle::SuppliedProductSerializer,
        order_cycle: @order_cycle
      )

      render text: {
        products: serializer,
        pagination: pagination_data(paginated_products)
      }.to_json
    end

    def pagination_data(paginated_products)
      {
        results: paginated_products.total_count,
        pages: paginated_products.num_pages,
        page: (params[:page] || DEFAULT_PAGE).to_i,
        per_page: (params[:per_page] || DEFAULT_PER_PAGE).to_i
      }
    end
  end
end
