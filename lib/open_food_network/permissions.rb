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

      Enterprise.where(id: coordinator_permitted | managed_permitted | managed_active | hubs_permitted | hubs_active)
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
      ids = order_cycle_exchange_ids_involving_my_enterprises(order_cycle) | order_cycle_exchange_ids_distributing_my_variants(order_cycle)

      Exchange.where(id: ids, order_cycle_id: order_cycle)
    end

    # Find the variants within an exchange that a user can POTENTIALLY see
    # Note that this does not determine whether they actually appear in outgoing exchanges
    # as this requires first that the variant is included in an incoming exchange
    def visible_variants_within(exchange)
      if exchange.incoming
        if managed_enterprises.pluck(:id).include?(exchange.receiver_id) || managed_enterprises.pluck(:id).include?(exchange.sender_id)
          # All variants belonging to the producer
          Spree::Variant.joins(:product).where('spree_products.supplier_id = (?)', exchange.sender_id)
        else
          [] # None
        end
      else
        if managed_enterprises.pluck(:id).include?(exchange.receiver_id) || managed_enterprises.pluck(:id).include?(exchange.sender_id)
          # Any variants of any producers that have granted the receiver P-OC
          producers = granting(:add_to_order_cycle, to: [exchange.receiver], scope: Enterprise.is_primary_producer)
          permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)
          # PLUS any variants that are already in the exchange, so things don't break
          active_variants = exchange.variants
          Spree::Variant.where(id: permitted_variants | active_variants)
        else
          # Any variants produced by MY PRODUCERS, where my producer has granted P-OC to the receiver
          producers = granting(:add_to_order_cycle, to: [exchange.receiver], scope: managed_enterprises.is_primary_producer)
          permitted_variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', producers)
          # PLUS any of my producers variants that are already in the exchange, so things don't break
          active_variants = exchange.variants.joins(:product).where('spree_products.supplier_id IN (?)', managed_enterprises.is_primary_producer)
          Spree::Variant.where(id: permitted_variants | active_variants)
        end
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

    def order_cycle_exchange_ids_distributing_my_variants(order_cycle)
      # Any outgoing exchange where the distributor has been granted P-OC by one or more of my producers
      hubs = granted(:add_to_order_cycle, by: managed_enterprises.is_primary_producer, scope: Enterprise.is_hub).pluck(:id)
      permitted_exchanges = order_cycle.exchanges.outgoing.where(receiver_id: hubs)

      # TODO: remove active_exchanges when we think it is safe to do so
      # active_exchanges is for backward compatability, before we restricted variants in each
      # outgoing exchange to those where the producer had granted P-OC to the distributor
      # For any of my managed producers, any outgoing exchanges with their variants
      variants = Spree::Variant.joins(:product).where('spree_products.supplier_id IN (?)', managed_enterprises.is_primary_producer)
      active_exchanges = order_cycle.exchanges.outgoing.with_any_variant(variants).pluck :id

      permitted_exchanges | active_exchanges
    end
  end
end
