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

    # Find the exchanges of an order cycle that an admin can manage
    def order_cycle_exchanges(order_cycle)
      enterprises = managed_enterprises + related_enterprises_with(:add_to_order_cycle)
      order_cycle.exchanges.to_enterprises(enterprises).from_enterprises(enterprises)
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

    def managed_and_related_enterprises_with(permission)
      managed_enterprise_ids = managed_enterprises.pluck :id
      permitted_enterprise_ids = related_enterprises_with(permission).pluck :id

      Enterprise.where('id IN (?)', managed_enterprise_ids + permitted_enterprise_ids)
    end


    def managed_enterprise_products
      Spree::Product.managed_by(@user)
    end

    def related_enterprise_products
      Spree::Product.where('supplier_id IN (?)', related_enterprises_with(:manage_products))
    end
  end
end
