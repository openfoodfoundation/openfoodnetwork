require 'open_food_network/scope_variant_to_hub'

module OpenFoodNetwork
  class ProductsAndInventoryReportBase
    attr_reader :params

    def initialize(user, params = {}, render_table = false)
      @user = user
      @params = params
      @render_table = render_table
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
      filter_on_hand filter_to_distributor filter_to_order_cycle filter_to_supplier variants
    end

    # Using the `in_stock?` method allows overrides by distributors.
    # It also allows the upgrade to Spree 2.0.
    def filter_on_hand(variants)
      if params[:report_type] == 'inventory'
        variants.select(&:in_stock?)
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
        # There are two quirks here:
        #
        # 1. Rails 3 uses only the last `where` clause of a column. So we can't
        #    use `variants.where(id: order_cycle.variants)` until we upgrade to
        #    Rails 4.
        #
        # 2. `order_cycle.variants` returns an array. So we need to use map
        #    instead of pluck.
        variants.where("spree_variants.id in (?)", order_cycle.variants.map(&:id))
      else
        variants
      end
    end
  end
end
