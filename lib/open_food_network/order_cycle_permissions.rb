# frozen_string_literal: true

require 'open_food_network/permissions'

module OpenFoodNetwork
  # Class which is used for determining the permissions around a single order cycle and user
  # both of which are set at initialization
  class OrderCyclePermissions < Permissions
    def initialize(user, order_cycle)
      super(user)
      @order_cycle = order_cycle
      @coordinator = order_cycle&.coordinator
    end

    # List of any enterprises whose exchanges I should be able to see in order_cycle
    # NOTE: the enterprises a given user can see actually in the OC interface depend on the
    # relationships of their enterprises to the coordinator of the OC, rather than on the OC itself
    def visible_enterprises
      return Enterprise.where("1=0") if @coordinator.blank?

      if managed_enterprise_ids.include? @coordinator.id
        coordinator_permitted_ids = [@coordinator]
        all_active_ids = []

        if @coordinator.sells == "any"
          # If the coordinator sells any, relationships come into play
          related_enterprises_granting(:add_to_order_cycle,
                                       to: [@coordinator.id]).each do |enterprise_id|
            coordinator_permitted_ids << enterprise_id
          end

          # As a safety net, we load all the enterprises involved in existing exchanges in this OC
          all_active_ids = @order_cycle.suppliers.pluck(:id) | @order_cycle.distributors.pluck(:id)
        end

        Enterprise.where(id: coordinator_permitted_ids | all_active_ids)
      else
        # Any enterprises that I manage directly, which have granted P-OC to the coordinator
        managed_permitted_ids = related_enterprises_granting(
          :add_to_order_cycle,
          to: [@coordinator.id],
          scope: managed_participating_enterprises
        )

        # Any hubs in this OC that have been granted P-OC by producers I manage in this OC
        hubs_permitted_ids = related_enterprises_granted(
          :add_to_order_cycle,
          by: managed_participating_producers.select("enterprises.id"),
          scope: @order_cycle.distributors
        )

        # Any hubs in this OC that have granted P-OC to producers I manage in this OC
        hubs_permitting_ids = related_enterprises_granting(
          :add_to_order_cycle,
          to: managed_participating_producers.select("enterprises.id"),
          scope: @order_cycle.distributors
        )

        # Any producers in this OC that have been granted P-OC by hubs I manage in this OC
        producers_permitted_ids = related_enterprises_granted(
          :add_to_order_cycle,
          by: managed_participating_hubs.select("enterprises.id"),
          scope: @order_cycle.suppliers
        )

        # Any producers in this OC that have granted P-OC to hubs I manage in this OC
        producers_permitting_ids = related_enterprises_granting(
          :add_to_order_cycle,
          to: managed_participating_hubs.select("enterprises.id"),
          scope: @order_cycle.suppliers
        )

        managed_active_ids = []
        hubs_active_ids = []
        producers_active_ids = []
        if @order_cycle
          # TODO: Remove this when all P-OC are sorted out
          # Any enterprises that I manage that are already in the order_cycle
          managed_active_ids = managed_participating_enterprises.pluck(:id)

          # TODO: Remove this when all P-OC are sorted out
          # Hubs that currently have outgoing exchanges distributing variants of producers I manage
          variants = variants_from_suppliers(managed_producer_ids)

          active_exchanges = @order_cycle.
            exchanges.outgoing.with_any_variant(variants.select("spree_variants.id"))

          hubs_active_ids = active_exchanges.map(&:receiver_id)

          # TODO: Remove this when all P-OC are sorted out
          # Any producers of variants that hubs I manage are currently distributing in this OC
          variant_ids = Spree::Variant.joins(:exchanges).
            where(
              "exchanges.receiver_id IN (?)
            AND exchanges.order_cycle_id = (?)
            AND exchanges.incoming = 'f'",
              managed_participating_hubs.select("enterprises.id"),
              @order_cycle
            ).pluck(:id).uniq

          product_ids = Spree::Product.joins(:variants).
            where("spree_variants.id IN (?)", variant_ids).pluck(:id).uniq

          producers_active_ids = Enterprise.joins(:supplied_products).
            where("spree_products.id IN (?)", product_ids).pluck(:id).uniq
        end

        ids = managed_permitted_ids | hubs_permitted_ids | hubs_permitting_ids \
          | producers_permitted_ids | producers_permitting_ids | managed_active_ids \
          | hubs_active_ids | producers_active_ids

        Enterprise.where(id: ids)
      end
    end

    # Find the exchanges of an order cycle that an admin can manage
    def visible_exchanges
      ids = order_cycle_exchange_ids_involving_my_enterprises |
            order_cycle_exchange_ids_distributing_my_variants |
            order_cycle_exchange_ids_with_distributable_variants

      Exchange.where(id: ids, order_cycle_id: @order_cycle)
    end

    # Find the variants that a user can POTENTIALLY see within incoming exchanges
    def visible_variants_for_incoming_exchanges_from(producer)
      if @order_cycle &&
         (user_manages_coordinator_or(producer) || user_is_permitted_add_to_oc_by(producer))
        all_variants_supplied_by(producer)
      else
        no_variants
      end
    end

    # Producer has granted P-OC to any of my managed hubs that are in this OC
    def user_is_permitted_add_to_oc_by(producer)
      EnterpriseRelationship.
        permitting(managed_participating_hubs.select("enterprises.id")).
        permitted_by(producer.id).
        with_permission(:add_to_order_cycle).
        present?
    end

    # Find the variants that a user can edit within incoming exchanges
    def editable_variants_for_incoming_exchanges_from(producer)
      if @order_cycle && user_manages_coordinator_or(producer)
        all_variants_supplied_by(producer)
      else
        no_variants
      end
    end

    def all_variants_supplied_by(producer)
      Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', producer)
    end

    def no_variants
      Spree::Variant.where("1=0")
    end

    def all_incoming_editable_variants
      valid_suppliers = visible_enterprises.select do |enterprise|
        user_manages_coordinator_or(enterprise)
      end.map(&:id)

      Spree::Variant.includes(product: :supplier).
        select("spree_variants.id, spree_variants.product_id, spree_products.supplier_id").
        joins(:product).where(spree_products: { supplier_id: valid_suppliers })
    end

    # Find the variants that a user is permitted see within outgoing exchanges
    # Note that this does not determine whether they actually appear in outgoing exchanges
    # as this requires first that the variant is included in an incoming exchange
    def visible_variants_for_outgoing_exchanges_to(hub)
      return Spree::Variant.where("1=0") unless @order_cycle

      if user_manages_coordinator_or(hub)
        visible_and_editable_variants(hub)
      else
        # Variants produced by MY PRODUCERS that are in this OC,
        #   where my producer has granted P-OC to the hub
        producer_ids = related_enterprises_granting(:add_to_order_cycle,
                                                    to: [hub.id],
                                                    scope: managed_participating_producers)
        permitted_variants = variants_from_suppliers(producer_ids)

        # PLUS my incoming producers' variants that are already in an outgoing exchange of this hub,
        #   so things don't break. TODO: Remove this when all P-OC are sorted out
        active_variants = Spree::Variant.joins(:exchanges, :product).
          where("exchanges.receiver_id = (?)
              AND spree_products.supplier_id IN (?)
              AND incoming = 'f'",
                hub.id,
                managed_producer_ids)

        Spree::Variant.where(id: permitted_variants | active_variants)
      end
    end

    # Find the variants that a user is permitted edit within outgoing exchanges
    def editable_variants_for_outgoing_exchanges_to(hub)
      return Spree::Variant.where("1=0") unless @order_cycle

      if user_manages_coordinator_or(hub)
        visible_and_editable_variants(hub)
      else
        # Any of my managed producers in this order cycle granted P-OC by the hub
        granted_producers = related_enterprises_granted(:add_to_order_cycle,
                                                        by: [hub.id],
                                                        scope: managed_participating_producers)

        # Variants produced by MY PRODUCERS that are in this OC,
        #   where my producer has granted P-OC to the hub
        granting_producer_ids = related_enterprises_granting(:add_to_order_cycle,
                                                             to: [hub.id],
                                                             scope: granted_producers)
        permitted_variants = variants_from_suppliers(granting_producer_ids)

        Spree::Variant.where(id: permitted_variants)
      end
    end

    private

    def visible_and_editable_variants(hub)
      # Producers that have granted the hub P-OC
      producer_ids = related_enterprises_granting(:add_to_order_cycle,
                                                  to: [hub.id],
                                                  scope: Enterprise.is_primary_producer)

      # Variants from Producers via permissions, and from the hub itself
      available_variants = variants_from_suppliers(producer_ids.to_a + [hub.id])

      # PLUS variants that are already in an outgoing exchange of this hub, so things don't break
      active_variants = active_outgoing_variants(hub)

      Spree::Variant.where(id: available_variants | active_variants)
    end

    def variants_from_suppliers(supplier_ids)
      Spree::Variant.joins(:product).where(spree_products: { supplier_id: supplier_ids })
    end

    def active_outgoing_variants(hub)
      @active_outgoing_variants ||=
        @order_cycle.exchanges.outgoing.where(receiver_id: hub).first&.variants || []
    end

    def user_manages_coordinator_or(enterprise)
      managed_enterprise_ids.include?(@coordinator.id) ||
        managed_enterprise_ids.include?(enterprise.id)
    end

    def managed_enterprise_ids
      @managed_enterprise_ids ||= managed_enterprises.pluck(:id)
    end

    def managed_producer_ids
      @managed_producer_ids ||= managed_enterprises.is_primary_producer.pluck(:id)
    end

    def managed_participating_enterprises
      return @managed_participating_enterprises unless @managed_participating_enterprises.nil?

      @managed_participating_enterprises = managed_enterprises.
        where(id: @order_cycle.suppliers | @order_cycle.distributors)
    end

    def managed_participating_hubs
      return @managed_participating_hubs unless @managed_participating_hubs.nil?

      @managed_participating_hubs = managed_participating_enterprises.is_hub
    end

    def managed_participating_producers
      return @managed_participating_producers unless @managed_participating_producers.nil?

      @managed_participating_producers = managed_participating_enterprises.is_primary_producer
    end

    def order_cycle_exchange_ids_involving_my_enterprises
      # Any exchanges that my managed enterprises are involved in directly
      @order_cycle.exchanges.involving(managed_enterprise_ids).pluck :id
    end

    def order_cycle_exchange_ids_with_distributable_variants
      # Find my managed hubs in this order cycle
      hubs = managed_participating_hubs
      # Any incoming exchange where the producer has granted P-OC to one or more of those hubs
      producer_ids = related_enterprises_granting(:add_to_order_cycle,
                                                  to: hubs.select("enterprises.id"),
                                                  scope: Enterprise.is_primary_producer)
      permitted_exchange_ids = @order_cycle.
        exchanges.incoming.where(sender_id: producer_ids).pluck :id

      # TODO: remove active_exchanges when we think it is safe to do so
      # active_exchanges is for backward compatability, before we restricted variants in each
      # outgoing exchange to those where the producer had granted P-OC to the distributor
      # For any of my managed hubs in this OC,
      #   any incoming exchanges supplying variants in my outgoing exchanges
      variant_ids = Spree::Variant.joins(:exchanges).
        where("exchanges.receiver_id IN (?)
            AND exchanges.order_cycle_id = (?)
            AND exchanges.incoming = 'f'",
              hubs.select("enterprises.id"),
              @order_cycle).pluck(:id).uniq

      product_ids = Spree::Product.joins(:variants).
        where(spree_variants: { id: variant_ids }).pluck(:id).uniq

      producer_ids = Enterprise.joins(:supplied_products).
        where(spree_products: { id: product_ids }).pluck(:id).uniq

      active_exchange_ids = @order_cycle.exchanges.incoming.where(sender_id: producer_ids).pluck :id

      permitted_exchange_ids | active_exchange_ids
    end

    def order_cycle_exchange_ids_distributing_my_variants
      # Find my producers in this order cycle
      producer_ids = managed_participating_producers.pluck :id
      # Outgoing exchanges with distributor that has been granted P-OC by 1 or more of the producers
      hub_ids = related_enterprises_granted(:add_to_order_cycle,
                                            by: producer_ids,
                                            scope: Enterprise.is_hub)
      permitted_exchange_ids = @order_cycle.exchanges.outgoing.where(receiver_id: hub_ids).pluck :id

      # TODO: remove active_exchanges when we think it is safe to do so
      # active_exchanges is for backward compatability, before we restricted variants in each
      # outgoing exchange to those where the producer had granted P-OC to the distributor
      # For any of my managed producers, any outgoing exchanges with their variants
      variants = variants_from_suppliers(producer_ids)
      active_exchange_ids = @order_cycle.
        exchanges.outgoing.with_any_variant(variants.select("spree_variants.id")).pluck :id

      permitted_exchange_ids | active_exchange_ids
    end
  end
end
