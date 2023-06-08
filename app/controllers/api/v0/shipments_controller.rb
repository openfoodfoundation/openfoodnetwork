# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

module Api
  module V0
    class ShipmentsController < Api::V0::BaseController
      respond_to :json

      before_action :find_order
      before_action :refuse_changing_cancelled_orders, only: [:add, :remove]
      before_action :find_and_update_shipment, only: [:ship, :ready, :add, :remove]

      def create
        variant = scoped_variant(params[:variant_id])
        quantity = params[:quantity].to_i
        @shipment = get_or_create_shipment(params[:stock_location_id])

        @order.contents.add(variant, quantity, @shipment)

        @shipment.refresh_rates
        @shipment.save!

        OrderWorkflow.new(@order).advance_to_payment if @order.line_items.any?

        render json: @shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

      def update
        authorize! :read, Spree::Shipment
        @shipment = @order.shipments.find_by!(number: params[:id])
        params[:shipment] ||= []

        @shipment.fee_adjustment.fire_events(:open)

        if @shipment.update(shipment_params)
          @order.update_totals_and_states
        end

        @shipment.fee_adjustment.close

        render json: @shipment.reload, serializer: Api::ShipmentSerializer, status: :ok
      end

      def ready
        authorize! :read, Spree::Shipment
        unless @shipment.ready?
          if @shipment.can_ready?
            @shipment.ready!
          else
            render(json: { error: I18n.t(:cannot_ready, scope: "spree.api.shipment") },
                   status: :unprocessable_entity) && return
          end
        end
        render json: @shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

      def ship
        authorize! :read, Spree::Shipment
        unless @shipment.shipped?
          @shipment.ship!
        end
        render json: @shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

      def add
        variant = scoped_variant(params[:variant_id])
        quantity = params[:quantity].to_i

        @order.contents.add(variant, quantity, @shipment)
        @order.recreate_all_fees!

        render json: @shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

      def remove
        variant = scoped_variant(params[:variant_id])
        quantity = params[:quantity].to_i
        restock_item = params.fetch(:restock_item, "true") == "true"

        @order.contents.remove(variant, quantity, @shipment, restock_item)
        @shipment.reload if @shipment.persisted?

        render json: @shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

      private

      def find_order
        @order = Spree::Order.find_by!(number: params[:order_id])
        authorize! :read, @order
      end

      def find_and_update_shipment
        @shipment = @order.shipments.find_by!(number: params[:id])
        @shipment.update(shipment_params)
        @shipment.reload
      end

      def refuse_changing_cancelled_orders
        render status: :unprocessable_entity if @order.canceled?
      end

      def scoped_variant(variant_id)
        variant = Spree::Variant.find(variant_id)
        OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor).scope(variant)
        variant
      end

      def get_or_create_shipment(stock_location_id)
        @order.shipment || @order.shipments.create(stock_location_id: stock_location_id)
      end

      def shipment_params
        return {} unless params.has_key? :shipment

        params.require(:shipment).permit(:tracking, :selected_shipping_rate_id)
      end
    end
  end
end
