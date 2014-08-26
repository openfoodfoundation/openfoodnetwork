module OpenFoodNetwork
  class Permissions
    def initialize(user)
      @user = user
    end

    # Find enterprises that an admin is allowed to add to an order cycle
    def order_cycle_enterprises
      managed_enterprise_ids = managed_enterprises.pluck :id
      permitted_enterprise_ids = related_enterprises_with(:add_to_order_cycle).pluck :id

      Enterprise.where('id IN (?)', managed_enterprise_ids + permitted_enterprise_ids)
    end

    # Find the exchanges of an order cycle that an admin can manage
    def order_cycle_exchanges(order_cycle)
      enterprises = managed_enterprises + related_enterprises_with(:add_to_order_cycle)
      order_cycle.exchanges.to_enterprises(enterprises).from_enterprises(enterprises)
    end


    private

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
  end
end
