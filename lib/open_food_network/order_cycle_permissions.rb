module OpenFoodNetwork
  # Class which is used for determining the permissions around a single order cycle and user
  # both of which are set at initialization
  class OrderCyclePermissions < Permissions
    def initialize(user, order_cycle)
      super(user)
      @order_cycle = order_cycle
      @coordinator = order_cycle.andand.coordinator
    end

    # List of any enterprises whose exchanges I should be able to see in order_cycle
    # NOTE: the enterprises a given user can see actually in the OC interface depend on the relationships
    # of their enterprises to the coordinator of the order cycle, rather than on the order cycle itself
    def visible_enterprises
      return Enterprise.where("1=0") unless @coordinator.present?
      if managed_enterprises.include? @coordinator
        coordinator_permitted = [@coordinator]
        all_active = []

        if @coordinator.sells == "any"
          # If the coordinator sells any, relationships come into play
          related_enterprises_granting(:add_to_order_cycle, to: [@coordinator]).pluck(:id).each do |enterprise_id|
            coordinator_permitted << enterprise_id
          end

          # As a safety net, we should load all of the enterprises invloved in existing exchanges in this order cycle
          all_active = @order_cycle.suppliers.pluck(:id) | @order_cycle.distributors.pluck(:id)
        end

        Enterprise.where(id: coordinator_permitted | all_active)
      else
        # Any enterprises that I manage directly, which have granted P-OC to the coordinator
        managed_permitted = related_enterprises_granting(:add_to_order_cycle, to: [@coordinator], scope: managed_participating_enterprises ).pluck(:id)

        # Any hubs in this OC that have been granted P-OC by producers I manage in this OC
        hubs_permitted = related_enterprises_granted(:add_to_order_cycle, by: managed_participating_producers, scope: @order_cycle.distributors).pluck(:id)

        # Any hubs in this OC that have granted P-OC to producers I manage in this OC
        hubs_permitting = related_enterprises_granting(:add_to_order_cycle, to: managed_participating_producers, scope: @order_cycle.distributors).pluck(:id)

        # Any producers in this OC that have been granted P-OC by hubs I manage in this OC
        producers_permitted = related_enterprises_granted(:add_to_order_cycle, by: managed_participating_hubs, scope: @order_cycle.suppliers).pluck(:id)

        # Any producers in this OC that have granted P-OC to hubs I manage in this OC
        producers_permitting = related_enterprises_granting(:add_to_order_cycle, to: managed_participating_hubs, scope: @order_cycle.suppliers).pluck(:id)

        managed_active = []
        hubs_active = []
        producers_active = []
        if @order_cycle
          # TODO: Remove this when all P-OC are sorted out
          # Any enterprises that I manage that are already in the order_cycle
          managed_active = managed_participating_enterprises.pluck(:id)

          # TODO: Remove this when all P-OC are sorted out
          # Any hubs that currently have outgoing exchanges distributing variants of producers I manage
          variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', managed_enterprises.is_primary_producer)
          active_exchanges = @order_cycle.exchanges.outgoing.with_any_variant(variants)
          hubs_active = active_exchanges.map(&:receiver_id)

          # TODO: Remove this when all P-OC are sorted out
          # Any producers of variants that hubs I manage are currently distributing in this OC
          variants = Spree::Variant.joins(:exchanges).where("exchanges.receiver_id IN (?) AND exchanges.order_cycle_id = (?) AND exchanges.incoming = 'f'", managed_participating_hubs, @order_cycle).pluck(:id).uniq
          products = Spree::Product.joins(:variants_including_master).where("spree_variants.id IN (?)", variants).pluck(:id).uniq
          producers_active = Enterprise.joins(:supplied_products).where("spree_products.id IN (?)", products).pluck(:id).uniq
        end

        ids = managed_permitted | hubs_permitted | hubs_permitting | producers_permitted | producers_permitting | managed_active | hubs_active | producers_active

        Enterprise.where(id: ids.sort )
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
      return Spree::Variant.where("1=0") unless @order_cycle

      if user_manages_coordinator_or(producer)
        # All variants belonging to the producer
        Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', producer)
      else
        # All variants of the producer if it has granted P-OC to any of my managed hubs that are in this order cycle
        permitted = EnterpriseRelationship.permitting(managed_participating_hubs).
          permitted_by(producer).with_permission(:add_to_order_cycle).present?
        if permitted
          Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', producer)
        else
          Spree::Variant.where("1=0")
        end
      end
    end

    # Find the variants that a user can edit within incoming exchanges
    def editable_variants_for_incoming_exchanges_from(producer)
      return Spree::Variant.where("1=0") unless @order_cycle

      if user_manages_coordinator_or(producer)
        # All variants belonging to the producer
        Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', producer)
      else
        Spree::Variant.where("1=0")
      end
    end

    # Find the variants that a user is permitted see within outgoing exchanges
    # Note that this does not determine whether they actually appear in outgoing exchanges
    # as this requires first that the variant is included in an incoming exchange
    def visible_variants_for_outgoing_exchanges_to(hub)
      return Spree::Variant.where("1=0") unless @order_cycle

      if user_manages_coordinator_or(hub)
        # TODO: Use variants_stockable_by(hub) for this?

        # Any variants produced by the coordinator, for outgoing exchanges with itself
        # TODO: isn't this completely redundant given the assignment of hub_variants below?
        coordinator_variants = []
        if hub == @coordinator
          coordinator_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', @coordinator)
        end

        # Any variants of any producers that have granted the hub P-OC
        producers = related_enterprises_granting(:add_to_order_cycle, to: [hub], scope: Enterprise.is_primary_producer)
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)

        hub_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', hub)

        # PLUS any variants that are already in an outgoing exchange of this hub, so things don't break
        # TODO: Remove this when all P-OC are sorted out
        active_variants = []
        @order_cycle.exchanges.outgoing.where(receiver_id: hub).limit(1).each do |exchange|
          active_variants = exchange.variants
        end

        Spree::Variant.where(id: coordinator_variants | hub_variants | permitted_variants | active_variants)
      else
        # Any variants produced by MY PRODUCERS that are in this order cycle, where my producer has granted P-OC to the hub
        producers = related_enterprises_granting(:add_to_order_cycle, to: [hub], scope: managed_participating_producers)
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)

        # PLUS any of my incoming producers' variants that are already in an outgoing exchange of this hub, so things don't break
        # TODO: Remove this when all P-OC are sorted out
        active_variants = Spree::Variant.joins(:exchanges, :product).
          where("exchanges.receiver_id = (?) AND spree_products.supplier_id IN (?) AND incoming = 'f'", hub, managed_enterprises.is_primary_producer)

        Spree::Variant.where(id: permitted_variants | active_variants)
      end
    end

    # Find the variants that a user is permitted edit within outgoing exchanges
    def editable_variants_for_outgoing_exchanges_to(hub)
      return Spree::Variant.where("1=0") unless @order_cycle

      if user_manages_coordinator_or(hub)
        # Any variants produced by the coordinator, for outgoing exchanges with itself
        coordinator_variants = []
        if hub == @coordinator
          coordinator_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', @coordinator)
        end

        # Any variants of any producers that have granted the hub P-OC
        producers = related_enterprises_granting(:add_to_order_cycle, to: [hub], scope: Enterprise.is_primary_producer)
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)

        hub_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', hub)

        # PLUS any variants that are already in an outgoing exchange of this hub, so things don't break
        # TODO: Remove this when all P-OC are sorted out
        active_variants = []
        @order_cycle.exchanges.outgoing.where(receiver_id: hub).limit(1).each do |exchange|
          active_variants = exchange.variants
        end

        Spree::Variant.where(id: coordinator_variants | hub_variants | permitted_variants | active_variants)
      else
        # Any of my managed producers in this order cycle granted P-OC by the hub
        granted_producers = related_enterprises_granted(:add_to_order_cycle, by: [hub], scope: managed_participating_producers)

        # Any variants produced by MY PRODUCERS that are in this order cycle, where my producer has granted P-OC to the hub
        granting_producers = related_enterprises_granting(:add_to_order_cycle, to: [hub], scope: granted_producers)
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', granting_producers)

        Spree::Variant.where(id: permitted_variants)
      end
    end


    private

    def user_manages_coordinator_or(enterprise)
      managed_enterprises.pluck(:id).include?(@coordinator.id) || managed_enterprises.pluck(:id).include?(enterprise.id)
    end

    def managed_participating_enterprises
      return @managed_participating_enterprises unless @managed_participating_enterprises.nil?
      @managed_participating_enterprises = managed_enterprises.where(id: @order_cycle.suppliers | @order_cycle.distributors)
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
      @order_cycle.exchanges.involving(managed_enterprises).pluck :id
    end

    def order_cycle_exchange_ids_with_distributable_variants
      # Find my managed hubs in this order cycle
      hubs = managed_participating_hubs
      # Any incoming exchange where the producer has granted P-OC to one or more of those hubs
      producers = related_enterprises_granting(:add_to_order_cycle, to: hubs, scope: Enterprise.is_primary_producer).pluck :id
      permitted_exchanges = @order_cycle.exchanges.incoming.where(sender_id: producers).pluck :id

      # TODO: remove active_exchanges when we think it is safe to do so
      # active_exchanges is for backward compatability, before we restricted variants in each
      # outgoing exchange to those where the producer had granted P-OC to the distributor
      # For any of my managed hubs in this OC, any incoming exchanges supplying variants in my outgoing exchanges
      variants = Spree::Variant.joins(:exchanges).where("exchanges.receiver_id IN (?) AND exchanges.order_cycle_id = (?) AND exchanges.incoming = 'f'", hubs, @order_cycle).pluck(:id).uniq
      products = Spree::Product.joins(:variants_including_master).where("spree_variants.id IN (?)", variants).pluck(:id).uniq
      producers = Enterprise.joins(:supplied_products).where("spree_products.id IN (?)", products).pluck(:id).uniq
      active_exchanges = @order_cycle.exchanges.incoming.where(sender_id: producers).pluck :id

      permitted_exchanges | active_exchanges
    end

    def order_cycle_exchange_ids_distributing_my_variants
      # Find my producers in this order cycle
      producers = managed_participating_producers.pluck :id
      # Any outgoing exchange where the distributor has been granted P-OC by one or more of those producers
      hubs = related_enterprises_granted(:add_to_order_cycle, by: producers, scope: Enterprise.is_hub)
      permitted_exchanges = @order_cycle.exchanges.outgoing.where(receiver_id: hubs).pluck :id

      # TODO: remove active_exchanges when we think it is safe to do so
      # active_exchanges is for backward compatability, before we restricted variants in each
      # outgoing exchange to those where the producer had granted P-OC to the distributor
      # For any of my managed producers, any outgoing exchanges with their variants
      variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)
      active_exchanges = @order_cycle.exchanges.outgoing.with_any_variant(variants).pluck :id

      permitted_exchanges | active_exchanges
    end
  end
end
