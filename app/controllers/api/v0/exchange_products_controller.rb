# frozen_string_literal: true

# This controller lists products that can be added to an exchange
#
# Pagination is optional and can be required by using param[:page]
module Api
  module V0
    class ExchangeProductsController < Api::V0::BaseController
      include PaginationData
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
        if exchange_params[:exchange_id].present?
          load_data_from_exchange
        else
          load_data_from_other_params
        end

        render_variant_count && return if params[:action_name] == "variant_count"

        render_paginated_products
      end

      private

      def render_variant_count
        render plain: {
          count: variants.count
        }.to_json
      end

      def variants
        renderer.exchange_variants(@incoming, @enterprise)
      end

      def products
        renderer.exchange_products(@incoming, @enterprise)
      end

      def renderer
        @renderer ||= ExchangeProductsRenderer.
          new(@order_cycle, spree_current_user)
      end

      def load_data_from_exchange
        exchange = Exchange.find_by(id: exchange_params[:exchange_id])

        @order_cycle = exchange.order_cycle
        @incoming = exchange.incoming
        @enterprise = exchange.sender
      end

      def load_data_from_other_params
        @enterprise = Enterprise.find_by(id: exchange_params[:enterprise_id])

        # This will be a string (eg "true") when it arrives via params, but we want a boolean
        @incoming = ActiveModel::Type::Boolean.new.cast exchange_params[:incoming]

        if exchange_params[:order_cycle_id]
          @order_cycle = OrderCycle.find_by(id: exchange_params[:order_cycle_id])
        elsif !@incoming
          raise "order_cycle_id is required to list products for new outgoing exchange"
        end
      end

      def render_paginated_products
        results = products

        if pagination_required?
          @pagy, results = pagy(results,
                                items: params[:per_page] || DEFAULT_PER_PAGE)
        end

        serialized_products = ActiveModel::ArraySerializer.new(
          results,
          each_serializer: Api::Admin::ForOrderCycle::SuppliedProductSerializer,
          order_cycle: @order_cycle
        )

        render json: {
          products: serialized_products,
          pagination: pagination_data
        }
      end

      def exchange_params
        params.permit(:enterprise_id, :exchange_id, :order_cycle_id, :incoming).
          to_h.with_indifferent_access
      end
    end
  end
end
