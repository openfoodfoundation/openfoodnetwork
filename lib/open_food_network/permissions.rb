module OpenFoodNetwork
  class Permissions
    def initialize(user)
      @user = user
    end

    def can_manage_complex_order_cycles?
      managed_and_related_enterprises_with(:add_to_order_cycle).any? do |e|
        e.sells == 'any'
      end
    end

    # Find enterprises that an admin is allowed to add to an order cycle
    def order_cycle_enterprises
      managed_and_related_enterprises_with :add_to_order_cycle
    end

    # List of any enterprises whose exchanges I should be able to see in order_cycle
    # NOTE: the enterprises a given user can see actually in the OC interface depend on the relationships
    # of their enterprises to the coordinator of the order cycle, rather than on the order cycle itself
    # (until such time as we implement friends of friends)
    def order_cycle_enterprises_for(options={})
      # Can provide a coordinator OR an order cycle. Use just coordinator for new order cycles
      # if both are provided, coordinator will be ignored, and the coordinator of the OC will be used
      return Enterprise.where("1=0") unless options[:coordinator] || options[:order_cycle]
      coordinator = options[:coordinator]
      order_cycle = nil
      if options[:order_cycle]
        order_cycle = options[:order_cycle]
        coordinator = order_cycle.coordinator
      end


      if coordinator.sells == "own"

        # Coordinators that sell own can only see themselves in the OC interface
        coordinator_permitted = []
        if managed_enterprises.include? coordinator
          coordinator_permitted << coordinator
        end
        Enterprise.where(id: coordinator_permitted)

      else
        # If the coordinator sells any, relationships come into play

        # If I manage the coordinator (or possibly in the future, if coordinator has made order cycle a friends of friend OC)
        # Any hubs that have granted the coordinator P-OC (or any enterprises that have granted mine P-OC if we do friends of friends)
        coordinator_permitted = []
        if managed_enterprises.include? coordinator
          coordinator_permitted = granting(:add_to_order_cycle, to: [coordinator]).pluck(:id)
          coordinator_permitted << coordinator
        end

        # Any enterprises that I manage directly, which have granted P-OC to the coordinator
        managed_permitted = granting(:add_to_order_cycle, to: [coordinator], scope: managed_enterprises).pluck(:id)

        # Any hubs that have been granted P-OC by producers I manage
        hubs_permitted = granted(:add_to_order_cycle, by: managed_enterprises.is_primary_producer, scope: Enterprise.is_hub).pluck(:id)

        # Any producers that have granted P-OC to hubs I manage
        producers_permitted = granting(:add_to_order_cycle, to: managed_enterprises.is_hub, scope: Enterprise.is_primary_producer).pluck(:id)

        managed_active = []
        hubs_active = []
        if order_cycle
          # TODO: remove this when permissions are all sorted out
          # Any enterprises that I manage that are already in the order_cycle
          managed_active = managed_enterprises.where(id: order_cycle.suppliers | order_cycle.distributors).pluck(:id)

          # TODO: Remove this when all P-OC are sorted out
          # Any hubs that currently have outgoing exchanges distributing variants of producers I manage
          variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', managed_enterprises.is_primary_producer)
          active_exchanges = order_cycle.exchanges.outgoing.with_any_variant(variants)
          hubs_active = active_exchanges.map(&:receiver_id)
        end

        Enterprise.where(id: coordinator_permitted | managed_permitted | managed_active | hubs_permitted | producers_permitted | hubs_active)
      end
    end

    # Find enterprises for which an admin is allowed to edit their profile
    def editable_enterprises
      managed_and_related_enterprises_with :edit_profile
    end

    def variant_override_hubs
      managed_and_related_enterprises_with(:add_to_order_cycle).is_hub
    end

    def variant_override_producers
      producer_ids = variant_override_enterprises_per_hub.values.flatten.uniq
      Enterprise.where(id: producer_ids)
    end

    # For every hub that an admin manages, show all the producers for which that hub may
    # override variants
    # {hub1_id => [producer1_id, producer2_id, ...], ...}
    def variant_override_enterprises_per_hub
      hubs = managed_and_related_enterprises_with(:add_to_order_cycle).is_distributor

      # Permissions granted by create_variant_overrides relationship from producer to hub
      permissions = Hash[
           EnterpriseRelationship.
           permitting(hubs).
           with_permission(:create_variant_overrides).
           group_by { |er| er.child_id }.
           map { |child_id, ers| [child_id, ers.map { |er| er.parent_id }] }
          ]

      # We have permission to create variant overrides for any producers we manage, for any
      # hub we can add to an order cycle
      managed_producer_ids = managed_enterprises.is_primary_producer.pluck(:id)
      if managed_producer_ids.any?
        hubs.each do |hub|
          permissions[hub.id] = ((permissions[hub.id] || []) + managed_producer_ids).uniq
        end
      end

      permissions
    end

    # Find the exchanges of an order cycle that an admin can manage
    def order_cycle_exchanges(order_cycle)
      ids = order_cycle_exchange_ids_involving_my_enterprises(order_cycle) |
        order_cycle_exchange_ids_distributing_my_variants(order_cycle) |
        order_cycle_exchange_ids_with_distributable_variants(order_cycle)

      Exchange.where(id: ids, order_cycle_id: order_cycle)
    end

    # Find the variants that a user can POTENTIALLY see within incoming exchanges
    def visible_variants_for_incoming_exchanges_between(producer, coordinator, options={})
      return Spree::Variant.where("1=0") unless options[:order_cycle]
      if managed_enterprises.pluck(:id).include?(producer.id) || managed_enterprises.pluck(:id).include?(coordinator.id)
        # All variants belonging to the producer
        Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', producer)
      else
        # All variants of the producer if it has granted P-OC to any of my managed hubs that are in this order cycle
        permitted = EnterpriseRelationship.permitting(managed_hubs_in(options[:order_cycle])).
        permitted_by(producer).with_permission(:add_to_order_cycle).present?
        if permitted
          Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', producer)
        else
          Spree::Variant.where("1=0")
        end
      end
    end

    # Find the variants that a user can edit within incoming exchanges
    def editable_variants_for_incoming_exchanges_between(producer, coordinator, options={})
      return Spree::Variant.where("1=0") unless options[:order_cycle]
      if managed_enterprises.pluck(:id).include?(producer.id) || managed_enterprises.pluck(:id).include?(coordinator.id)
        # All variants belonging to the producer
        Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', producer)
      else
        Spree::Variant.where("1=0")
      end
    end

    # Find the variants that a user is permitted see within outgoing exchanges
    # Note that this does not determine whether they actually appear in outgoing exchanges
    # as this requires first that the variant is included in an incoming exchange
    def visible_variants_for_outgoing_exchanges_between(coordinator, hub, options={})
      return Spree::Variant.where("1=0") unless options[:order_cycle]
      if managed_enterprises.pluck(:id).include?(hub.id) || managed_enterprises.pluck(:id).include?(coordinator.id)
        # Any variants produced by the coordinator, for outgoing exchanges with itself
        coordinator_variants = []
        if hub == coordinator
          coordinator_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', coordinator)
        end

        # Any variants of any producers that have granted the hub P-OC
        producers = granting(:add_to_order_cycle, to: [hub], scope: Enterprise.is_primary_producer)
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)

        # PLUS any variants that are already in an outgoing exchange of this hub, so things don't break
        # TODO: Remove this when all P-OC are sorted out
        active_variants = []
        options[:order_cycle].exchanges.outgoing.where(receiver_id: hub).limit(1).each do |exchange|
          active_variants = exchange.variants
        end

        Spree::Variant.where(id: coordinator_variants | permitted_variants | active_variants)
      else
        # Any variants produced by MY PRODUCERS that are in this order cycle, where my producer has granted P-OC to the hub
        producers = granting(:add_to_order_cycle, to: [hub], scope: managed_producers_in(options[:order_cycle]))
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)

        # PLUS any of my incoming producers' variants that are already in an outgoing exchange of this hub, so things don't break
        # TODO: Remove this when all P-OC are sorted out
        active_variants = Spree::Variant.joins(:exchanges, :product).
        where("exchanges.receiver_id = (?) AND spree_products.supplier_id IN (?) AND incoming = 'f'", hub, managed_enterprises.is_primary_producer)

        Spree::Variant.where(id: permitted_variants | active_variants)
      end
    end

    # Find the variants that a user is permitted edit within outgoing exchanges
    def editable_variants_for_outgoing_exchanges_between(coordinator, hub, options={})
      return Spree::Variant.where("1=0") unless options[:order_cycle]
      if managed_enterprises.pluck(:id).include?(hub.id) || managed_enterprises.pluck(:id).include?(coordinator.id)
        # Any variants produced by the coordinator, for outgoing exchanges with itself
        coordinator_variants = []
        if hub == coordinator
          coordinator_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', coordinator)
        end

        # Any variants of any producers that have granted the hub P-OC
        producers = granting(:add_to_order_cycle, to: [hub], scope: Enterprise.is_primary_producer)
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)

        # PLUS any variants that are already in an outgoing exchange of this hub, so things don't break
        # TODO: Remove this when all P-OC are sorted out
        active_variants = []
        options[:order_cycle].exchanges.outgoing.where(receiver_id: hub).limit(1).each do |exchange|
          active_variants = exchange.variants
        end

        Spree::Variant.where(id: coordinator_variants | permitted_variants | active_variants)
      else
        # Any of my managed producers in this order cycle granted P-OC by the hub
        granted_producers = granted(:add_to_order_cycle, by: [hub], scope: managed_producers_in(options[:order_cycle]))

        # Any variants produced by MY PRODUCERS that are in this order cycle, where my producer has granted P-OC to the hub
        granting_producers = granting(:add_to_order_cycle, to: [hub], scope: granted_producers)
        permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', granting_producers)

        Spree::Variant.where(id: permitted_variants )
      end
    end

    def managed_products
      managed_enterprise_products_ids = managed_enterprise_products.pluck :id
      permitted_enterprise_products_ids = related_enterprise_products.pluck :id
      Spree::Product.where('id IN (?)', managed_enterprise_products_ids + permitted_enterprise_products_ids)
    end

    def managed_product_enterprises
      managed_and_related_enterprises_with :manage_products
    end

    def manages_one_enterprise?
      @user.enterprises.length == 1
    end


    private

    def managed_and_related_enterprises_with(permission)
      managed_enterprise_ids = managed_enterprises.pluck :id
      permitting_enterprise_ids = related_enterprises_with(permission).pluck :id

      Enterprise.where('id IN (?)', managed_enterprise_ids + permitting_enterprise_ids)
    end

    def managed_enterprises
      Enterprise.managed_by(@user)
    end

    def managed_hubs_in(order_cycle)
      Enterprise.with_order_cycles_as_distributor_outer.where("order_cycles.id = (?)", order_cycle.id)
      .merge(managed_enterprises.is_hub)
    end

    def managed_producers_in(order_cycle)
      Enterprise.with_order_cycles_as_supplier_outer.where("order_cycles.id = (?)", order_cycle.id)
      .merge(managed_enterprises.is_primary_producer)
    end

    def related_enterprises_with(permission)
      parent_ids = EnterpriseRelationship.
        permitting(managed_enterprises).
        with_permission(permission).
        pluck(:parent_id)

      Enterprise.where('id IN (?)', parent_ids)
    end

    def granting(permission, options={})
      parent_ids = EnterpriseRelationship.
        permitting(options[:to] || managed_enterprises).
        with_permission(permission).
        pluck(:parent_id)

        (options[:scope] || Enterprise).where('enterprises.id IN (?)', parent_ids)
    end

    def granted(permission, options={})
      child_ids = EnterpriseRelationship.
        permitted_by(options[:by] || managed_enterprises).
        with_permission(permission).
        pluck(:child_id)

        (options[:scope] || Enterprise).where('enterprises.id IN (?)', child_ids)
    end

    def managed_enterprise_products
      Spree::Product.managed_by(@user)
    end

    def related_enterprise_products
      Spree::Product.where('supplier_id IN (?)', related_enterprises_with(:manage_products))
    end

    def order_cycle_exchange_ids_involving_my_enterprises(order_cycle)
      # Any exchanges that my managed enterprises are involved in directly
      order_cycle.exchanges.involving(managed_enterprises).pluck :id
    end

    def order_cycle_exchange_ids_with_distributable_variants(order_cycle)
      # Find my managed hubs in this order cycle
      hubs = managed_hubs_in(order_cycle)
      # Any incoming exchange where the producer has granted P-OC to one or more of those hubs
      producers = granting(:add_to_order_cycle, to: hubs, scope: Enterprise.is_primary_producer).pluck :id
      permitted_exchanges = order_cycle.exchanges.incoming.where(sender_id: producers).pluck :id

      # TODO: remove active_exchanges when we think it is safe to do so
      # active_exchanges is for backward compatability, before we restricted variants in each
      # outgoing exchange to those where the producer had granted P-OC to the distributor
      # For any of my managed hubs in this OC, any incoming exchanges supplying variants in my outgoing exchanges
      variants = Spree::Variant.joins(:exchanges).where("exchanges.receiver_id IN (?) AND exchanges.order_cycle_id = (?) AND exchanges.incoming = 'f'", hubs, order_cycle).pluck(:id).uniq
      products = Spree::Product.joins(:variants_including_master).where("spree_variants.id IN (?)", variants).pluck(:id).uniq
      producers = Enterprise.joins(:supplied_products).where("spree_products.id IN (?)", products).pluck(:id).uniq
      active_exchanges = order_cycle.exchanges.incoming.where(sender_id: producers).pluck :id

      permitted_exchanges | active_exchanges
    end

    def order_cycle_exchange_ids_distributing_my_variants(order_cycle)
      # Find my producers in this order cycle
      producers = managed_producers_in(order_cycle).pluck :id
      # Any outgoing exchange where the distributor has been granted P-OC by one or more of those producers
      hubs = granted(:add_to_order_cycle, by: producers, scope: Enterprise.is_hub)
      permitted_exchanges = order_cycle.exchanges.outgoing.where(receiver_id: hubs).pluck :id

      # TODO: remove active_exchanges when we think it is safe to do so
      # active_exchanges is for backward compatability, before we restricted variants in each
      # outgoing exchange to those where the producer had granted P-OC to the distributor
      # For any of my managed producers, any outgoing exchanges with their variants
      variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)
      active_exchanges = order_cycle.exchanges.outgoing.with_any_variant(variants).pluck :id

      permitted_exchanges | active_exchanges
    end
  end
end
