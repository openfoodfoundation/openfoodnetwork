# frozen_string_literal: false

module OrderManagement
  module Subscriptions
    class VariantsList
      # Includes the following variants:
      # - Variants of permitted producers
      # - Variants of hub
      # - Variants that are in outgoing exchanges where the hub is receiver
      def self.eligible_variants(distributor)
        query = Spree::Variant.where(supplier_id: permitted_producer_ids(distributor))

        exchange_variant_ids = outgoing_exchange_variant_ids(distributor)
        if exchange_variant_ids.present?
          query = query.or(Spree::Variant.where(id: exchange_variant_ids))
        end

        query
      end

      def self.in_open_and_upcoming_order_cycles?(distributor, schedule, variant)
        scope = ExchangeVariant.joins(exchange: { order_cycle: :schedules })
          .where(variant_id: variant, exchanges: { incoming: false, receiver_id: distributor })
          .merge(OrderCycle.not_closed)
        scope = scope.where(schedules: { id: schedule })
        scope.any?
      end

      def self.permitted_producer_ids(distributor)
        other_permitted_producer_ids = EnterpriseRelationship.joins(:parent)
          .permitting(distributor.id).with_permission(:add_to_order_cycle)
          .merge(Enterprise.is_primary_producer)
          .pluck(:parent_id)

        # Append to the potentially gigantic array instead of using union, which creates a new array
        # The db IN statement won't care if there's a duplicate.
        other_permitted_producer_ids << distributor.id
      end

      def self.outgoing_exchange_variant_ids(distributor)
        ExchangeVariant.select("DISTINCT exchange_variants.variant_id").joins(:exchange)
          .where(exchanges: { incoming: false, receiver_id: distributor.id })
          .pluck(:variant_id)
      end
    end
  end
end
