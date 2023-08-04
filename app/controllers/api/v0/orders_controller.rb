# frozen_string_literal: true

module Api
  module V0
    class OrdersController < Api::V0::BaseController
      include PaginationData

      def index
        authorize! :admin, Spree::Order

        orders = SearchOrders.new(params, current_api_user).orders

        if pagination_required?
          @pagy, orders = pagy(orders,
                               items: params[:per_page] || default_per_page)
        end

        render json: {
          orders: serialized_orders(orders),
          pagination: pagination_data
        }
      end

      def show
        authorize! :read, order
        render json: order, serializer: Api::OrderDetailedSerializer, current_order: order
      end

      def update
        authorize! :admin, order

        order.update!(order_params)
        render json: order, serializer: Api::OrderDetailedSerializer, current_order: order
      end

      def ship
        authorize! :admin, order

        if order.ship
          render json: order.reload, serializer: Api::Admin::OrderSerializer, status: :ok
        else
          render json: { error: I18n.t('api.orders.failed_to_update') },
                 status: :unprocessable_entity
        end
      end

      def capture
        authorize! :admin, order

        payment_capture = OrderCaptureService.new(order)

        if payment_capture.call
          render json: order.reload, serializer: Api::Admin::OrderSerializer, status: :ok
        elsif payment_capture.gateway_error.present?
          error_during_processing(payment_capture.gateway_error)
        else
          payment_capture_failed
        end
      end

      private

      def payment_capture_failed
        render json: { error: I18n.t(:payment_processing_failed) }, status: :unprocessable_entity
      end

      def serialized_orders(orders)
        ActiveModel::ArraySerializer.new(
          orders,
          each_serializer: Api::Admin::OrderSerializer
        )
      end

      def order
        @order ||= Spree::Order.
          where(number: params[:id]).
          includes(line_items: { variant: [:product, :stock_items, :default_price] }).
          first!
      end

      def order_params
        params.permit(:note)
      end
    end
  end
end
