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
        @shipment = @order.shipment || @order.shipments.create

        line_item = @order.contents.add(variant, quantity, @shipment)
        return invalid_resource!(line_item) unless line_item.errors.empty?

        finalize_shipment_addition
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

        unless @shipment.ready? || @shipment.can_ready?
          return render(
            json: { error: I18n.t(:cannot_ready, scope: "spree.api.shipment") },
            status: :unprocessable_entity
          )
        end

        @shipment.ready! unless @shipment.ready?

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

        line_item = @order.contents.add(variant, quantity, @shipment)
        return invalid_resource!(line_item) unless line_item.errors.empty?

        finalize_shipment_addition
      end

      def remove
        variant = scoped_variant(params[:variant_id])
        quantity = params[:quantity].to_i
        restock_item = params.fetch(:restock_item, "true") == "true"

        @order.contents.remove(variant, quantity, @shipment, restock_item)
        @shipment.reload if @shipment.persisted?

        @order.recreate_all_fees!
        AmendBackorderJob.perform_later(@order) if @order.completed?

        render json: @shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

      private

      # Shared tail of #create and #add, once a line item has been added
      # successfully: recreates fees, advances the order toward payment when
      # possible, and renders the order's current shipment.
      def finalize_shipment_addition
        # Fees must be recreated before advancing to payment: advancing runs
        # apply_customer_credit (Spree::Order::Checkout's before_transition to:
        # :payment), which sizes the credit payment off order.total as it stands
        # at that moment — if fees aren't applied yet, the credit payment is
        # created short.
        @order.recreate_all_fees!
        AmendBackorderJob.perform_later(@order) if @order.completed?

        # Only orders still before payment need advancing; doing this
        # unconditionally would also refresh shipping rates/cost on
        # completed-but-unshipped orders, and calling advance_to_payment on an
        # order already at/past payment returns nil (not true), which the
        # return-value check below would otherwise misread as a stall.
        if @order.before_payment_state?
          @shipment.refresh_rates
          @shipment.save!

          if @order.line_items.any?
            advanced = Orders::WorkflowService.new(@order).advance_to_payment
            # A stall with no ship address yet is normal mid-construction state
            # (e.g. an admin adding products before visiting Customer Details) —
            # only treat a stall as an error once there's an address to actually
            # fail shipping against, i.e. a genuine shipping-method misconfiguration.
            return invalid_resource!(@order) if !advanced && @order.ship_address.present?
          end
        end

        # advance_to_payment can rebuild the order's shipments from scratch
        # (Spree::Order::Checkout's before_transition to: :delivery), which
        # destroys @shipment — re-resolve the current one rather than
        # rendering a stale/deleted record. See #14787.
        render json: @order.reload.shipment, serializer: Api::ShipmentSerializer, status: :ok
      end

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
        variant = Spree::Variant.with_deleted.find(variant_id)

        OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor).scope(variant)

        variant
      end

      def shipment_params
        return {} unless params.key? :shipment

        params.require(:shipment).permit(:tracking, :selected_shipping_rate_id)
      end
    end
  end
end
