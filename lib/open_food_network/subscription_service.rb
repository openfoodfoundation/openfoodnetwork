module OpenFoodNetwork
  class SubscriptionService
    # Includes the following variants:
    # - Variants of permitted producers
    # - Variants of hub
    # - Variants that are in outgoing exchanges where the hub is receiver
    def self.eligible_variants(distributor)
      permitted_order_cycle_enterprise_ids = EnterpriseRelationship.permitting(distributor)
        .with_permission(:add_to_order_cycle).pluck(:parent_id)
      permitted_producer_ids = Enterprise.is_primary_producer
        .where('enterprises.id IN (?)', permitted_order_cycle_enterprise_ids).pluck(:id)

      outgoing_exchange_variant_ids = ExchangeVariant
        .select("DISTINCT exchange_variants.variant_id")
        .joins(:exchange)
        .where(exchanges: { incoming: false, receiver_id: distributor.id })
        .pluck(:variant_id)

      variant_conditions = ["spree_products.supplier_id IN (?)", permitted_producer_ids | [distributor.id]]
      if outgoing_exchange_variant_ids.present?
        variant_conditions[0] << " OR spree_variants.id IN (?)"
        variant_conditions << outgoing_exchange_variant_ids
      end

      Spree::Variant.joins(:product).where(is_master: false).where(*variant_conditions)
    end

    def self.in_open_and_upcoming_order_cycles?(distributor, schedule, variant)
      scope = ExchangeVariant.joins(exchange: { order_cycle: :schedules })
        .where(variant_id: variant, exchanges: { incoming: false, receiver_id: distributor })
        .merge(OrderCycle.not_closed)
      scope = scope.where(schedules: { id: schedule })
      scope.any?
    end
  end
end
