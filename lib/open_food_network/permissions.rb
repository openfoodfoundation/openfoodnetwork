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

    # Find enterprises for which an admin is allowed to edit their profile
    def editable_enterprises
      managed_and_related_enterprises_with :edit_profile
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

        (options[:scope] || Enterprise).where('id IN (?)', parent_ids)
    end

    def granted(permission, options={})
      child_ids = EnterpriseRelationship.
        permitted_by(options[:by] || managed_enterprises).
        with_permission(permission).
        pluck(:child_id)

        (options[:scope] || Enterprise).where('id IN (?)', child_ids)
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
