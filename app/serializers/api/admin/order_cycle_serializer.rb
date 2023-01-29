# frozen_string_literal: true

require 'open_food_network/order_cycle_permissions'

module Api
  module Admin
    class OrderCycleSerializer < ActiveModel::Serializer
      attributes :id, :name, :orders_open_at, :orders_close_at, :coordinator_id, :exchanges,
                 :editable_variants_for_incoming_exchanges,
                 :editable_variants_for_outgoing_exchanges,
                 :visible_variants_for_outgoing_exchanges,
                 :viewing_as_coordinator, :schedule_ids, :subscriptions_count

      has_many :coordinator_fees, serializer: Api::IdSerializer

      def orders_open_at
        object.orders_open_at.to_s
      end

      def orders_close_at
        object.orders_close_at.to_s
      end

      def viewing_as_coordinator
        Enterprise.managed_by(options[:current_user]).include? object.coordinator
      end

      def subscriptions_count
        ProxyOrder.not_canceled.where(order_cycle_id: object.id).count
      end

      def exchanges
        scoped_exchanges = permissions.visible_exchanges.by_enterprise_name

        ActiveModel::ArraySerializer.
          new(scoped_exchanges, each_serializer: Api::Admin::ExchangeSerializer,
                                current_user: options[:current_user],
                                preloaded_tags: BatchTaggableTagsQuery.call(scoped_exchanges))
      end

      def editable_variants_for_incoming_exchanges
        variant_ids_by_supplier_id(permissions.all_incoming_editable_variants.all)
      end

      def editable_variants_for_outgoing_exchanges
        # For each enterprise that the current user is able to see in this order cycle,
        # work out which variants should be editable within incoming exchanges from that enterprise
        editable = {}
        visible_enterprises.each do |enterprise|
          variants = permissions.editable_variants_for_outgoing_exchanges_to(enterprise).pluck(:id)
          editable[enterprise.id] = variants if variants.any?
        end
        editable
      end

      def visible_variants_for_outgoing_exchanges
        # For each enterprise that the current user is able to see in this order cycle,
        # work out which variants should be visible within outgoing exchanges from that enterprise
        visible = {}
        visible_enterprises.each do |enterprise|
          # This is hopefully a temporary measure, pending the arrival of multiple named inventories
          # for shops. We need this here to allow hubs to restrict visible variants to only those in
          # their inventory if they so choose
          variants = if enterprise.prefers_product_selection_from_inventory_only?
                       permissions.
                         visible_variants_for_outgoing_exchanges_to(enterprise).
                         visible_for(enterprise)
                     else
                       permissions.
                         visible_variants_for_outgoing_exchanges_to(enterprise).
                         not_hidden_for(enterprise)
                     end.pluck(:id)
          visible[enterprise.id] = variants if variants.any?
        end
        visible
      end

      private

      def permissions
        @permissions ||= OpenFoodNetwork::OrderCyclePermissions.new(options[:current_user], object)
      end

      def visible_enterprises
        @visible_enterprises ||= permissions.visible_enterprises
      end

      def variant_ids_by_supplier_id(variants)
        grouped_by_supplier = variants.group_by(&:supplier_id)
        grouped_by_supplier.each do |supplier_id, grouped_variants|
          grouped_by_supplier[supplier_id] = grouped_variants.map(&:id)
        end
      end
    end
  end
end
