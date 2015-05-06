module OpenFoodNetwork
  class Permissions
    def initialize(user)
      @user = user
    end

    def can_manage_complex_order_cycles?
      managed_and_related_enterprises_granting(:add_to_order_cycle).any? do |e|
        e.sells == 'any'
      end
    end

    # Find enterprises that an admin is allowed to add to an order cycle
    def order_cycle_enterprises
      managed_and_related_enterprises_granting :add_to_order_cycle
    end

    def enterprises_managed_or_granting_add_to_order_cycle
      # Return enterprises that the user manages and those that have granted P-OC to managed enterprises
      if admin?
        Enterprise.scoped
      else
        managed_and_related_enterprises_granting :add_to_order_cycle
      end
    end

    # Find enterprises for which an admin is allowed to edit their profile
    def editable_enterprises
      managed_and_related_enterprises_granting :edit_profile
    end

    def variant_override_hubs
      managed_and_related_enterprises_granting(:add_to_order_cycle).is_hub
    end

    def variant_override_producers
      producer_ids = variant_override_enterprises_per_hub.values.flatten.uniq
      Enterprise.where(id: producer_ids)
    end

    # For every hub that an admin manages, show all the producers for which that hub may
    # override variants
    # {hub1_id => [producer1_id, producer2_id, ...], ...}
    def variant_override_enterprises_per_hub
      hubs = managed_and_related_enterprises_granting(:add_to_order_cycle).is_distributor

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

    # Find enterprises that an admin is allowed to add to an order cycle
    def visible_orders
      # Any orders that I can edit
      editable = editable_orders.pluck(:id)

      # Any orders placed through hubs that my producers have granted P-OC, and which contain my their products
      # This is pretty complicated but it's looking for order where at least one of my producers has granted
      # P-OC to the distributor AND the order contains products of at least one of THE SAME producers
      granted_distributors = granted(:add_to_order_cycle, by: managed_enterprises.is_primary_producer)
      produced = Spree::Order.with_line_items_variants_and_products_outer.
      where(
      "spree_orders.distributor_id IN (?) AND spree_products.supplier_id IN (?)",
      granted_distributors,
      related_enterprises_granting(:add_to_order_cycle, to: granted_distributors).merge(managed_enterprises.is_primary_producer)
      ).pluck(:id)

      Spree::Order.where(id: editable | produced)
    end

    # Find enterprises that an admin is allowed to add to an order cycle
    def editable_orders
      # Any orders placed through any hub that I manage
      managed = Spree::Order.where(distributor_id: managed_enterprises.pluck(:id)).pluck(:id)

      # Any order that is placed through an order cycle one of my managed enterprises coordinates
      coordinated = Spree::Order.where(order_cycle_id: coordinated_order_cycles.pluck(:id)).pluck(:id)

      Spree::Order.where(id: managed | coordinated )
    end

    def visible_line_items
      # Any line items that I can edit
      editable = editable_line_items.pluck(:id)

      # Any from visible orders, where the product is produced by one of my managed producers
      produced = Spree::LineItem.where(order_id: visible_orders.pluck(:id)).joins(:product).
      where('spree_products.supplier_id IN (?)', managed_enterprises.is_primary_producer.pluck(:id))

      Spree::LineItem.where(id: editable | produced)
    end

    def editable_line_items
      Spree::LineItem.where(order_id: editable_orders)
    end

    def managed_products
      managed_enterprise_products_ids = managed_enterprise_products.pluck :id
      permitted_enterprise_products_ids = related_enterprise_products.pluck :id
      Spree::Product.where('id IN (?)', managed_enterprise_products_ids + permitted_enterprise_products_ids)
    end

    def managed_product_enterprises
      managed_and_related_enterprises_granting :manage_products
    end

    def manages_one_enterprise?
      @user.enterprises.length == 1
    end


    private

    def admin?
      @user.admin?
    end

    def managed_and_related_enterprises_granting(permission)
      managed_enterprise_ids = managed_enterprises.pluck :id
      permitting_enterprise_ids = related_enterprises_granting(permission).pluck :id

      Enterprise.where('id IN (?)', managed_enterprise_ids + permitting_enterprise_ids)
    end

    def managed_enterprises
      return @managed_enterprises unless @managed_enterprises.nil?
      @managed_enterprises = Enterprise.managed_by(@user)
    end

    def coordinated_order_cycles
      return @coordinated_order_cycles unless @coordinated_order_cycles.nil?
      @coordinated_order_cycles = OrderCycle.managed_by(@user)
    end

    def related_enterprises_granting(permission, options={})
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
      Spree::Product.where('supplier_id IN (?)', related_enterprises_granting(:manage_products))
    end
  end
end
