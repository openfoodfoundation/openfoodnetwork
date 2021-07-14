# frozen_string_literal: true

module Api
  module V0
    class OrdersController < Api::V0::BaseController
      include PaginationData

      def show
        authorize! :read, order
        render json: order, serializer: Api::OrderDetailedSerializer, current_order: order
      end

      def index
        authorize! :admin, Spree::Order

        orders = SearchOrders.new(params, current_api_user).orders

        @pagy, orders = pagy(orders, items: params[:per_page] || default_per_page) if pagination_required?

        render json: {
          orders: serialized_orders(orders),
          pagination: pagination_data
        }
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

        pending_payment = order.pending_payments.first

        return payment_capture_failed unless order.payment_required? && pending_payment

        if pending_payment.capture!
          render json: order.reload, serializer: Api::Admin::OrderSerializer, status: :ok
        else
          payment_capture_failed
        end
      rescue Spree::Core::GatewayError => e
        error_during_processing(e)
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
    end
  end
end
