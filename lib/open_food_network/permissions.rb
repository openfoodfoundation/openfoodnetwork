module OpenFoodNetwork
  class Permissions
    def initialize(user)
      @user = user
    end

    # Find producers for which an admin is allowed to add their products to an order cycle
    def order_cycle_producers
      (managed_producers + related_producers_with(:add_products_to_order_cycle)).
        sort_by(&:name)
    end

    # Find the exchanges of an order cycle that an admin can manage
    def order_cycle_exchanges(order_cycle)
      enterprises = managed_enterprises + related_enterprises_with(:add_products_to_order_cycle)
      order_cycle.exchanges.to_enterprises(enterprises).from_enterprises(enterprises)
    end


    private

    def managed_enterprises
      Enterprise.managed_by(@user)
    end

    def managed_producers
      managed_enterprises.is_primary_producer.by_name
    end

    def related_enterprises_with(permission)
      parent_ids = EnterpriseRelationship.
        permitting(managed_enterprises).
        with_permission(permission).
        pluck(:parent_id)

      Enterprise.where('id IN (?)', parent_ids)
    end

    def related_producers_with(permission)
      related_enterprises_with(permission).is_primary_producer
    end
  end
end
