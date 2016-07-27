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
    def visible_enterprises_for_order_reports
      managed_and_related_enterprises_with :add_to_order_cycle
    end

    def visible_enterprises
      # Return enterprises that the user manages and those that have granted P-OC to managed enterprises
      managed_and_related_enterprises_granting :add_to_order_cycle
    end

    # Find enterprises for which an admin is allowed to edit their profile
    def editable_enterprises
      managed_and_related_enterprises_granting :edit_profile
    end

    def variant_override_hubs
      managed_enterprises.is_distributor
    end

    def variant_override_producers
      producer_ids = variant_override_enterprises_per_hub.values.flatten.uniq
      Enterprise.where(id: producer_ids)
    end

    # For every hub that an admin manages, show all the producers for which that hub may
    # override variants
    # {hub1_id => [producer1_id, producer2_id, ...], ...}
    def variant_override_enterprises_per_hub
      hubs = variant_override_hubs

      # Permissions granted by create_variant_overrides relationship from producer to hub
      permissions = Hash[
           EnterpriseRelationship.
             permitting(hubs).
             with_permission(:create_variant_overrides).
             group_by { |er| er.child_id }.
             map { |child_id, ers| [child_id, ers.map { |er| er.parent_id }] }
          ]

      # Allow a producer hub to override it's own products without explicit permission
      hubs.is_primary_producer.each do |hub|
        permissions[hub.id] ||= []
        permissions[hub.id] |= [hub.id]
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
      granted_distributors = related_enterprises_granted(:add_to_order_cycle, by: managed_enterprises.is_primary_producer)
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

    def editable_products
      managed_enterprise_products_ids = managed_enterprise_products.pluck :id
      permitted_enterprise_products_ids = products_supplied_by(
        related_enterprises_granting(:manage_products).pluck(:id)
      ).pluck :id
      Spree::Product.where('spree_products.id IN (?)', managed_enterprise_products_ids | permitted_enterprise_products_ids)
    end

    def visible_products
      managed_enterprise_products_ids = managed_enterprise_products.pluck :id
      permitted_enterprise_products_ids = products_supplied_by(
        related_enterprises_granting(:manage_products).pluck(:id) | related_enterprises_granting(:add_to_order_cycle).pluck(:id)
      ).pluck :id
      Spree::Product.where('spree_products.id IN (?)', managed_enterprise_products_ids | permitted_enterprise_products_ids)
    end

    def managed_product_enterprises
      managed_and_related_enterprises_granting :manage_products
    end

    def manages_one_enterprise?
      @user.enterprises.length == 1
    end

    def editable_schedules
      Schedule.joins(:order_cycles).where(order_cycles: { id: OrderCycle.managed_by(@user).pluck(:id) }).select("DISTINCT schedules.*")
    end

    def visible_schedules
      Schedule.joins(:order_cycles).where(order_cycles: { id: OrderCycle.accessible_by(@user).pluck(:id) }).select("DISTINCT schedules.*")
    end


    private

    def admin?
      @user.admin?
    end

    def managed_and_related_enterprises_granting(permission)
      if admin?
        Enterprise.scoped
      else
        managed_enterprise_ids = managed_enterprises.pluck :id
        permitting_enterprise_ids = related_enterprises_granting(permission).pluck :id

        Enterprise.where('id IN (?)', managed_enterprise_ids + permitting_enterprise_ids)
      end
    end

    def managed_and_related_enterprises_with(permission)
      if admin?
        Enterprise.scoped
      else
        managed = managed_enterprises.pluck(:id)
        granting = related_enterprises_granting(permission).pluck(:id)
        granted = related_enterprises_granted(permission).pluck(:id)
        Enterprise.where(id: managed | granting | granted)
      end
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

    def related_enterprises_granted(permission, options={})
      child_ids = EnterpriseRelationship.
        permitted_by(options[:by] || managed_enterprises).
        with_permission(permission).
        pluck(:child_id)

        (options[:scope] || Enterprise).where('enterprises.id IN (?)', child_ids)
    end

    def managed_enterprise_products
      Spree::Product.managed_by(@user)
    end

    def products_supplied_by(suppliers)
      Spree::Product.where('supplier_id IN (?)', suppliers)
    end
  end
end
