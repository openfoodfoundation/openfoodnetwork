module OpenFoodNetwork

  class ProductsAndInventoryReport
    def initialize(user, params = {})
      @user = user
      @params = params
      #@variants = fetch_variants
      # Fetch filter(variants) + filter(master_variants)
      # Fetch master variants
      #
      # Filter variants
      #
      # Merge variants
      #
      # Build table
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
    end

    def master_variants
      Spree::Variant.where(:is_master => true)
      .joins(:product)
      .where("(select spree_variants.id from spree_variants as other_spree_variants
                  WHERE other_spree_variants.product_id = spree_variants.product_id
                 AND other_spree_variants.is_master = 'f' LIMIT 1) IS NULL")
      .merge(Spree::Product.managed_by(@user))
    end
  end
end
