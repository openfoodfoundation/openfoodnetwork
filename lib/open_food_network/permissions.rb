# frozen_string_literal: true

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

    # Enterprises that an admin is allowed to add to an order cycle
    def visible_enterprises_for_order_reports
      managed_and_related_enterprises_with :add_to_order_cycle
    end

    # Enterprises that the user manages and those that have granted P-OC to managed enterprises
    def visible_enterprises
      managed_and_related_enterprises_granting :add_to_order_cycle
    end

    # Enterprises for which an admin is allowed to edit their profile
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
      permissions =
        EnterpriseRelationship.
          permitting(hubs.select("enterprises.id")).
          with_permission(:create_variant_overrides).
          group_by(&:child_id).
          transform_values { |ers| ers.map(&:parent_id) }

      # Allow a producer hub to override it's own products without explicit permission
      hubs.is_primary_producer.each do |hub|
        permissions[hub.id] ||= []
        permissions[hub.id] |= [hub.id]
      end

      permissions
    end

    def editable_products
      return Spree::Product.all if admin?

      Spree::Product.where(supplier_id: @user.enterprises).or(
        Spree::Product.where(supplier_id: related_enterprises_granting(:manage_products))
      )
    end

    def visible_products
      return Spree::Product.all if admin?

      Spree::Product.where(
        supplier_id: @user.enterprises
      ).or(
        Spree::Product.where(
          supplier_id: related_enterprises_granting(:manage_products) |
            related_enterprises_granting(:add_to_order_cycle)
        )
      )
    end

    def product_ids_supplied_by(supplier_ids)
      Spree::Product.where(supplier_id: supplier_ids).select(:id)
    end

    def managed_product_enterprises
      managed_and_related_enterprises_granting :manage_products
    end

    def manages_one_enterprise?
      @user.enterprises.length == 1
    end

    def editable_schedules
      Schedule.
        joins(:order_cycles).
        where(order_cycles: { id: OrderCycle.managed_by(@user).select("order_cycles.id") }).
        select("DISTINCT schedules.*")
    end

    def visible_schedules
      Schedule.
        joins(:order_cycles).
        where(order_cycles: { id: OrderCycle.managed_by(@user).select("order_cycles.id") }).
        select("DISTINCT schedules.*")
    end

    def editable_subscriptions
      Subscription.where(shop_id: managed_enterprises)
    end

    def visible_subscriptions
      editable_subscriptions
    end

    def managed_enterprises
      @managed_enterprises ||= Enterprise.managed_by(@user)
    end

    def coordinated_order_cycles
      return @coordinated_order_cycles unless @coordinated_order_cycles.nil?

      @coordinated_order_cycles = OrderCycle.managed_by(@user)
    end

    def related_enterprises_granting(permission, options = {})
      parent_ids = EnterpriseRelationship.
        permitting(options[:to] || managed_enterprises.select("enterprises.id")).
        with_permission(permission).
        select(:parent_id)

      (options[:scope] || Enterprise).where(id: parent_ids).select("enterprises.id")
    end

    def related_enterprises_granted(permission, options = {})
      child_ids = EnterpriseRelationship.
        permitted_by(options[:by] || managed_enterprises.select("enterprises.id")).
        with_permission(permission).
        select(:child_id)

      (options[:scope] || Enterprise).where(id: child_ids).select("enterprises.id")
    end

    private

    def admin?
      @user.admin?
    end

    def managed_and_related_enterprises_granting(permission)
      if admin?
        Enterprise.where(nil)
      else
        Enterprise.where(
          id: managed_enterprises.select("enterprises.id") |
                related_enterprises_granting(permission)
        )
      end
    end

    def managed_and_related_enterprises_with(permission)
      if admin?
        Enterprise.where(nil)
      else
        managed_enterprise_ids = managed_enterprises.select("enterprises.id")
        granting_enterprise_ids = related_enterprises_granting(permission)
        granted_enterprise_ids = related_enterprises_granted(permission)

        Enterprise.where(
          id: managed_enterprise_ids | granting_enterprise_ids | granted_enterprise_ids
        )
      end
    end

    def managed_enterprise_products
      Spree::Product.managed_by(@user)
    end
  end
end
