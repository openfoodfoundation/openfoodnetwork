module OpenFoodNetwork
  class ProductsAndInventoryReportBase
    attr_reader :params

    def initialize(user, params = {})
      @user = user
      @params = params
    end

    def permissions
      @permissions ||= OpenFoodNetwork::Permissions.new(@user)
    end

    def visible_products
      @visible_products ||= permissions.visible_products
    end

    def variants
      filter(child_variants)
    end

    def child_variants
      Spree::Variant.
        where(is_master: false).
        joins(:product).
        merge(visible_products).
        order('spree_products.name')
    end

    def filter(variants)
      filter_to_distributor filter_to_order_cycle filter_on_hand filter_to_supplier filter_not_deleted variants
    end

    def filter_not_deleted(variants)
      variants.not_deleted
    end

    def filter_on_hand(variants)
      if params[:report_type] == 'inventory'
        variants.where('spree_variants.count_on_hand > 0')
      else
        variants
      end
    end

    def filter_to_supplier(variants)
      if params[:supplier_id].to_i > 0
        variants.where("spree_products.supplier_id = ?", params[:supplier_id])
      else
        variants
      end
    end

    def filter_to_distributor(variants)
      if params[:distributor_id].to_i > 0
        distributor = Enterprise.find params[:distributor_id]
        scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
        variants.in_distributor(distributor).each { |v| scoper.scope(v) }
      else
        variants
      end
    end

    def filter_to_order_cycle(variants)
      if params[:order_cycle_id].to_i > 0
        order_cycle = OrderCycle.find params[:order_cycle_id]
        variants.where(id: order_cycle.variants)
      else
        variants
      end
    end
  end
end
