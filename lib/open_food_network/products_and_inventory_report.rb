module OpenFoodNetwork

  class ProductsAndInventoryReport
    attr_reader :params
    def initialize(user, params = {})
      @user = user
      @params = params
    end

    def header
      ["Supplier", "Product", "SKU", "Variant", "On Hand", "Price"]
    end

    def table
      variants.map do |variant|
        [variant.product.supplier.name,
         variant.product.name,
         variant.sku,
         variant.options_text,
         variant.count_on_hand,
         variant.price]
      end
    end

    def variants
      filter(child_variants) + filter(master_variants)
    end

    def child_variants
      Spree::Variant.where(:is_master => false)
      .joins(:product)
      .merge(Spree::Product.managed_by(@user))
      .order("spree_products.name")
    end

    def master_variants
      Spree::Variant.where(:is_master => true)
      .joins(:product)
      .where("(select spree_variants.id from spree_variants as other_spree_variants
                  WHERE other_spree_variants.product_id = spree_variants.product_id
                 AND other_spree_variants.is_master = 'f' LIMIT 1) IS NULL")
      .merge(Spree::Product.managed_by(@user))
      .order("spree_products.name")
    end

    def filter(variants)
      # NOTE: Ordering matters.
      # filter_to_order_cycle and filter_to_distributor return Arrays not Arel
      filter_to_distributor filter_to_order_cycle filter_on_hand filter_to_supplier variants
    end

    def filter_on_hand(variants)
      if params[:report_type] == "inventory"
        variants.where("spree_variants.count_on_hand > 0")
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
        variants.select do |v|
          Enterprise.distributing_product(v.product_id).include? distributor
        end
      else
        variants
      end
    end

    def filter_to_order_cycle(variants)
      if params[:order_cycle_id].to_i > 0
        order_cycle = OrderCycle.find params[:order_cycle_id]
        variants.select! { |v| order_cycle.variants.include? v }
      else
        variants
      end
    end
  end
end
