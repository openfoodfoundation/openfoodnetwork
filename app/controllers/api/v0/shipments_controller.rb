# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

module Api
  module V0
    class ShipmentsController < Api::V0::BaseController
      respond_to :json

      before_action :find_order
      before_action :find_and_update_shipment, only: [:ship, :ready, :add, :remove]

      def create
        variant = scoped_variant(params[:variant_id])
        quantity = params[:quantity].to_i
        @shipment = get_or_create_shipment(params[:stock_location_id])

        @order.contents.add(variant, quantity, nil, @shipment)

        @shipment.refresh_rates
        @shipment.save!

        render json: @shipment.reload, serializer: Api::ShipmentSerializer, status: :ok
      end

      def update
        authorize! :read, Spree::Shipment
        @shipment = @order.shipments.find_by!(number: params[:id])
        params[:shipment] ||= []
        unlock = params[:shipment].delete(:unlock)

        if unlock == 'yes'
          @shipment.fee_adjustment.open
        end

        @shipment.update(shipment_params[:shipment])

        if unlock == 'yes'
          @shipment.fee_adjustment.close
        end

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

        @order.contents.add(variant, quantity, nil, @shipment)
        @order.recreate_all_fees!

        render json: @shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

      def remove
        variant = scoped_variant(params[:variant_id])
        quantity = params[:quantity].to_i

        @order.contents.remove(variant, quantity, @shipment)
        @order.recreate_all_fees!
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
        @shipment.update(shipment_params[:shipment]) if shipment_params[:shipment].present?
        @shipment.reload
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
        params.permit(
          [:id, :order_id, :variant_id, :quantity,
           { shipment: [:tracking, :selected_shipping_rate_id] }]
        )
      end
    end
  end
end
